import 'movie.dart';

/// =============================================================================
/// MovieDetail —— 电影详情领域实体（详情页专用，对标 MovieDetail.kt）
/// =============================================================================
///
/// 与 [Movie] 的区别：Movie 是列表用的精简实体（只有列表展示需要的字段）；
/// MovieDetail 是详情页用的完整实体，额外包含：
///   - runtime（片长，分钟）
///   - genres（类型名列表，如 ["动作", "科幻"]）
///   - cast（主要演员表，前 N 条）
///   - similarMovies（相似推荐，TMDB 的 /movie/{id}/similar 结果）
///
/// 【为什么详情要单独一个 domain 类而不是扩展 Movie？】
///   列表和详情的字段差异大、生命周期不同（列表条目可能成百上千，详情一次一个）。
///   分开让 UI 和 State 类型清晰，避免 Movie 承载太多可空字段。
///   对标 Android 版 common-domain 同时有 Movie 和 MovieDetail 两个类。
///
/// 🍎 UIKit 类比：列表用 UITableViewCell 的 Model，详情页用独立的 DetailModel；
/// 🍎 SwiftUI 类比：struct MovieRow 和 struct MovieDetail 分开声明。
class MovieDetail {
  const MovieDetail({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.runtime,
    required this.genres,
    required this.cast,
    required this.similarMovies,
  });

  /// 电影 ID（= Movie.id，列表跳详情用的就是它）
  final int id;

  /// 电影名
  final String title;

  /// 剧情简介（详情页完整版，比列表可能更长）
  final String overview;

  /// 海报相对路径（可空）
  final String? posterPath;

  /// 背景大图相对路径（可空）
  final String? backdropPath;

  /// 评分（0~10）
  final double voteAverage;

  /// 上映日期 "YYYY-MM-DD"
  final String releaseDate;

  /// 片长（分钟，可空：少数电影未填）
  final int? runtime;

  /// 类型名列表（如 ["动作", "科幻"]，TMDB 已按 language 返回本地化名）
  final List<String> genres;

  /// 主要演员表（前 N 条，见 [Cast]）
  final List<Cast> cast;

  /// 相似推荐电影（精简 Movie 列表，点击可继续跳详情）
  final List<Movie> similarMovies;

  /// 完整海报 URL（w500）
  String get posterUrl =>
      posterPath == null ? '' : 'https://image.tmdb.org/t/p/w500$posterPath';

  /// 完整背景大图 URL（w780）
  String get backdropUrl =>
      backdropPath == null ? '' : 'https://image.tmdb.org/t/p/w780$backdropPath';

  /// 格式化评分：8.456 → "8.5"
  String get formattedVote => voteAverage.toStringAsFixed(1);

  /// 格式化片长：123 → "2小时3分钟"（< 60 时只显示分钟）
  String get formattedRuntime {
    if (runtime == null) return '未知';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h == 0) return '$m分钟';
    return '$h小时$m分钟';
  }

  /// 把详情的精简字段映射成 [Movie]，用于相似推荐列表复用 [Movie] 的卡片组件。
  /// （不暴露 cast/runtime/genres，因为这些是详情页专属。）
  Movie toMovie() => Movie(
        id: id,
        title: title,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
        genreIds: const [], // 详情页 Movie 没有 genreIds（TMDB 详情返回 genres 对象不是 id 列表）
      );
}

/// 演员实体（详情页用，对标 Cast.kt）
///
/// TMDB /movie/{id}?append_to_response=credits 返回的 cast 数组元素：
///   { id, name, character, profile_path, order, ... }
/// order 越小越靠前（主演在前），详情页只展示前 10 条。
class Cast {
  const Cast({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  final int id;

  /// 演员名（TMDB 按 language 返回，zh-CN 一般是中文）
  final String name;

  /// 饰演角色名
  final String character;

  /// 头像相对路径（可空：少数演员无头像）
  final String? profilePath;

  /// 完整头像 URL（w185，比海报小）
  String get profileUrl =>
      profilePath == null ? '' : 'https://image.tmdb.org/t/p/w185$profilePath';
}
