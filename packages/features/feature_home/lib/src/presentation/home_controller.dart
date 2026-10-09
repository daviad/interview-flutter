import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/home_dtos.dart';
import '../data/providers.dart';
import 'home_state.dart';

part 'home_controller.g.dart';

/// =============================================================================
/// HomeController —— 首页 MVI 中枢（对标 HomeViewModel.kt）
/// =============================================================================
///
/// 【@riverpod 是什么？】
///   riverpod_generator 提供的代码生成注解（= KSP 之于 Hilt）。
///   写 `@riverpod class XxxController extends _$XxxController`，
///   build_runner 会生成 xxxControllerProvider（页面用 ref.watch 订阅）。
///   这个类等价 Android 的 @HiltViewModel ViewModel：
///     - build() 方法 = init {} 初始状态 + 首次加载
///     - 对外方法 = sendIntent(HomeIntent.Xxx)（Refresh 等）
///     - 给 state 赋值 = _state.value = ...（StateFlow 推新值 → UI 自动重建）
///
/// 🍎 UIKit 类比：DI 容器生成的 ObservableObject；
///    state 变化触发 objectWillChange → View 刷新（≈ @Published）。
/// 🍎 SwiftUI 类比：@MainActor final class HomeViewModel: ObservableObject {
///    @Published var state: HomeState = .loading }
@riverpod
class HomeController extends _$HomeController {
  /// build() = ViewModel 的初始状态 + init{refresh()}。
  /// 返回首帧状态（Loading），同时异步发起首次加载。
  ///
  /// 注意：build() 执行期间 Notifier 的 state 尚未初始化，此时读/写 state 会
  /// 抛 Bad state（uninitialized provider），所以首次加载要延迟到构建完成后
  /// （Future 调度到下一个事件循环）——等价 Android init{} 里在 ViewModel
  /// 创建完毕后再 viewModelScope.launch。
  @override
  HomeState build() {
    Future<void>.microtask(() => _load(isRefresh: false));
    return const HomeLoading();
  }

  /// 下拉刷新 / 错误页重试（对标 HomeIntent.Refresh）。
  Future<void> refresh() => _load(isRefresh: true);

  /// 核心业务：并发拉取热门 + 正在上映（对标 ViewModel.refresh()）。
  ///
  /// - 首次加载：Loading → Success / Error（全屏切换）
  /// - 下拉刷新：Success(isRefreshing=true) → Success(..., refreshMessage)
  ///   刷新失败不清空旧数据，只给 Snackbar 消息。
  Future<void> _load({required bool isRefresh}) async {
    final homeApi = ref.read(homeApiProvider);

    // 保留旧数据（对标 Kotlin: val previous = _state.value as? HomeUiState.Success）
    final previous = state is HomeSuccess ? state as HomeSuccess : null;

    if (isRefresh && previous != null) {
      state = previous.copyWith(isRefreshing: true, refreshMessage: null);
    } else {
      state = const HomeLoading();
    }

    try {
      // 并发请求：Future.wait = coroutineScope { async { } + async { } }
      // 🍎 Swift 类比：async let popular = ...; async let now = ...; try await (popular, now)
      final results = await Future.wait<MovieResponseDto>([
        homeApi.getPopularMovies(),
        homeApi.getNowPlayingMovies(),
      ]);

      state = HomeSuccess(
        popularMovies: results[0].results.map((dto) => dto.toMovie()).toList(),
        nowPlayingMovies: results[1].results.map((dto) => dto.toMovie()).toList(),
        isRefreshing: false,
        refreshMessage: isRefresh ? '刷新成功' : null,
      );
    } on DioException catch (e) {
      // 网络层异常（超时/DNS/代理失败/404 等）
      const message = '网络请求失败，请检查网络后重试';
      _emitError(isRefresh, previous, message, e);
    } catch (_) {
      const message = '数据解析失败，请稍后重试';
      _emitError(isRefresh, previous, message, null);
    }
  }

  void _emitError(bool isRefresh, HomeSuccess? previous, String message, Object? error) {
    if (isRefresh && previous != null) {
      // 刷新失败：保留旧数据，只提示消息（对标 refreshMessage = errorMsg）
      state = previous.copyWith(isRefreshing: false, refreshMessage: '刷新失败：$message');
    } else {
      // 首次加载失败：全屏错误页 + 重试按钮
      state = HomeError(message);
    }
  }
}
