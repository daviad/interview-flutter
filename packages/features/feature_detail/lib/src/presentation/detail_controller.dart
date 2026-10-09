import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/providers.dart';
import 'detail_state.dart';

part 'detail_controller.g.dart';

/// =============================================================================
/// DetailController —— 详情页 MVI 中枢（对标 DetailViewModel.kt）
/// =============================================================================
///
/// 【family provider —— 按 movieId 区分实例】
///   `@riverpod class DetailController extends _$DetailController` + build(int movieId)
///   会让 riverpod_generator 生成一个 family provider：调用方传 movieId 取对应实例。
///   不同电影 ID 对应独立的 Controller 实例（独立 state），缓存由 Riverpod 管理。
///
///   🍎 UIKit 类比：DetailViewController(movieId:) 工厂，每个 id 一个 VC；
///   🍎 SwiftUI 类比：View 接收 movieId 参数，@StateObject 按参数独立持有。
///
/// 【为什么 build 要 microtask 延迟首载？】
///   build() 执行期 Notifier.state 未初始化，直接读写会抛 Bad state。
///   Future.microtask 把 _load 推迟到 build 返回后再执行
///   （等价 Android init{} 后再 viewModelScope.launch）。
@riverpod
class DetailController extends _$DetailController {
  @override
  DetailState build(int movieId) {
    Future<void>.microtask(() => _load());
    return const DetailLoading();
  }

  /// 错误页重试（对标 DetailIntent.Retry）
  Future<void> retry() => _load();

  /// 核心业务：拉取详情（对标 DetailViewModel.loadDetail()）
  Future<void> _load() async {
    final detailApi = ref.read(detailApiProvider);
    state = const DetailLoading();
    try {
      final dto = await detailApi.getMovieDetail(movieId);
      state = DetailSuccess(detail: dto.toMovieDetail());
    } on DioException catch (_) {
      state = const DetailError('网络请求失败，请检查网络后重试');
    } catch (_) {
      state = const DetailError('数据解析失败，请稍后重试');
    }
  }
}
