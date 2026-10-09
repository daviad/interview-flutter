import 'package:moviely_core_domain/moviely_core_domain.dart';

/// =============================================================================
/// HomeState —— 首页 MVI 状态（对标 HomeUiState.kt，sealed 三态原样平移）
/// =============================================================================
///
/// Dart 3 的 sealed class 与 Kotlin sealed class 语义一致：
///   子类数量固定，switch 穷尽匹配（编译器强制覆盖所有分支）。
///
/// 🍎 UIKit 类比：一个基类 + Loading/Error/Success 三个子类，
///    View 根据 state 类型 switch 渲染（类似 enum 关联值状态机）。
/// 🍎 SwiftUI 类比：enum HomeState { case loading; case error(String); case success(...) }
///
/// 为什么不用 Riverpod 的 AsyncValue？
///   AsyncValue 自带 loading/data/error 三态，但「下拉刷新保留旧数据 + 刷新消息」
///   需要自定义字段（isRefreshing/refreshMessage），显式 sealed 状态与 Android
///   版 MVI 完全一一对应，更利于对照学习。
sealed class HomeState {
  const HomeState();
}

/// 首次加载：全屏转圈
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// 加载失败（首次）：全屏错误 + 重试
class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;
}

/// 加载成功（以及刷新中的复用态）
class HomeSuccess extends HomeState {
  const HomeSuccess({
    required this.popularMovies,
    required this.nowPlayingMovies,
    this.isRefreshing = false,
    this.refreshMessage,
  });

  final List<Movie> popularMovies;
  final List<Movie> nowPlayingMovies;

  /// 下拉刷新进行中（true 时 RefreshIndicator 显示转圈，旧列表不消失）
  final bool isRefreshing;

  /// 一次性刷新结果消息（"刷新成功"/"刷新失败：..."），消费后由 Controller 清空
  final String? refreshMessage;

  /// 只换刷新标志/消息，保留电影列表（= Kotlin data class copy）
  HomeSuccess copyWith({bool? isRefreshing, String? refreshMessage}) {
    return HomeSuccess(
      popularMovies: popularMovies,
      nowPlayingMovies: nowPlayingMovies,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshMessage: refreshMessage ?? this.refreshMessage,
    );
  }
}
