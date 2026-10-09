/// =============================================================================
/// Movie —— 领域层核心实体（电影，列表用）
/// =============================================================================
///
/// 对标 Android 工程：common-domain 的 `com.moviely.common.domain.model.Movie`
/// （Kotlin data class）。
///
/// 【为什么字段全部 final？】
///   领域实体必须不可变（immutable）：线程安全、可放心在多个 Provider 间共享，
///   状态变更时是「创建一个新对象」而不是「改掉旧对象」，符合 MVI 单向数据流。
///
///   🍎 UIKit 类比：实现了 NSCopying、所有属性 readonly/copy 的 Model NSObject；
///      Swift 里就是 `struct Movie`（值类型语义，let 字段，天然不可变）。
///   🍎 SwiftUI 类比：`struct Movie: Identifiable`（id 字段对应 Identifiable.id）。
///
/// 【Dart 没有 data class？】
///   Dart 不自动生成 toString/equals/copyWith；本工程刻意不引入 freezed
///   （Dart 3 sealed class + 手写不可变类已覆盖学习场景）。列表去重/刷新对比
///   靠 ValueKey(movie.id) 完成，不需要 == 。
///
/// 【为什么 domain 层硬编码图片 URL 前缀？】
///   与 Android 版 Movie.kt 保持一致：领域层零依赖（不 import core_network 的
///   常量文件），图片拼接规则属于领域模型自身的展示属性。
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
  });

  /// 电影 ID（TMDB 主键，列表 key、详情导航参数都用它）
  final int id;

  /// 电影名（TMDB 按 zh-CN 返回中文名，无中文时回退英文）
  final String title;

  /// 剧情简介
  final String overview;

  /// 海报相对路径（如 "/abc.jpg"）。TMDB 只给相对路径，完整 URL 见 [posterUrl]。
  /// 可空：少数电影没有海报 —— 对应 Kotlin 的 String? / Swift 的 String?
  final String? posterPath;

  /// 背景大图相对路径，可空
  final String? backdropPath;

  /// 评分（0~10，TMDB 返回浮点）
  final double voteAverage;

  /// 上映日期（字符串 "YYYY-MM-DD"，UI 直接展示）
  final String releaseDate;

  /// 类型 ID 列表（如 [28, 12] = 动作+冒险），不可变 List
  final List<int> genreIds;

  /// 完整海报 URL（w500 = 宽度 500px）。
  /// posterPath 为 null 时返回空串（UI 层用占位图兜底）。
  ///
  /// 🍎 UIKit 类比：重写 getter 的计算属性 `@property(readonly) NSURL *posterURL`
  /// 🍎 SwiftUI 类比：`var posterURL: URL { ... }` 计算属性
  String get posterUrl =>
      posterPath == null ? '' : 'https://image.tmdb.org/t/p/w500$posterPath';

  /// 完整背景大图 URL（w780，比海报宽）
  String get backdropUrl =>
      backdropPath == null ? '' : 'https://image.tmdb.org/t/p/w780$backdropPath';

  /// 格式化评分：8.456 → "8.5"（保留 1 位小数）。
  /// 对应 Kotlin 的 "%.1f".format(voteAverage)。
  String get formattedVote => voteAverage.toStringAsFixed(1);
}
