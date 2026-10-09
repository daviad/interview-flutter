import 'package:json_annotation/json_annotation.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';

part 'detail_dtos.g.dart';

/// =============================================================================
/// DetailDtos —— 详情模块私有 DTO（对标 feature-detail 的 DetailDtos.kt）
/// =============================================================================
///
/// 调用：GET /movie/{id}?append_to_response=credits,similar
///   TMDB 一次返回详情 + 演员表（credits）+ 相似推荐（similar）。
///   append_to_response 让多个端点合并成一个请求（对标 Kotlin 的批量请求）。
///
/// 【json_serializable 嵌套对象】
///   credits/similar 是嵌套对象，json_serializable 会递归调用嵌套 DTO 的
///   fromJson（前提：嵌套类也标 @JsonSerializable 且有 fromJson 工厂）。
///
/// 🍎 UIKit 类比：嵌套 Decodable struct（CreditsDto 内含 [CastDto]）。

/// /movie/{id} 响应 DTO（含 append_to_response 合并的 credits/similar）。
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class MovieDetailDto {
  const MovieDetailDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.runtime,
    required this.genres,
    required this.credits,
    required this.similar,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final int? runtime;
  final List<GenreDto> genres;
  final CreditsDto credits;
  final SimilarMoviePageDto similar;

  factory MovieDetailDto.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailDtoFromJson(json);

  /// DTO → Domain（对标 Kotlin DetailViewModel.toMovieDetail()）
  ///
  /// 取 cast 前 10 条（TMDB 已按 order 排序，主演在前）；
  /// similar 的 results 映射成 Movie 列表（复用列表卡片）。
  MovieDetail toMovieDetail() => MovieDetail(
        id: id,
        title: title,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
        runtime: runtime,
        genres: genres.map((g) => g.name).toList(),
        cast: credits.cast.take(10).map((c) => c.toCast()).toList(),
        similarMovies: similar.results.map((m) => m.toMovie()).toList(),
      );
}

/// 类型 DTO（TMDB 详情返回 genres: [{id, name}]，列表返回 genre_ids: [int]）
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class GenreDto {
  const GenreDto({required this.id, required this.name});

  final int id;
  final String name;

  factory GenreDto.fromJson(Map<String, dynamic> json) =>
      _$GenreDtoFromJson(json);
}

/// 演职员容器（append_to_response=credits 返回 {cast: [...], crew: [...]}）
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class CreditsDto {
  const CreditsDto({required this.cast});

  final List<CastDto> cast;

  factory CreditsDto.fromJson(Map<String, dynamic> json) =>
      _$CreditsDtoFromJson(json);
}

/// 演员 DTO（cast 数组元素）
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class CastDto {
  const CastDto({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  final int id;
  final String name;
  final String character;
  final String? profilePath;

  factory CastDto.fromJson(Map<String, dynamic> json) =>
      _$CastDtoFromJson(json);

  /// DTO → Domain Cast
  Cast toCast() => Cast(
        id: id,
        name: name,
        character: character,
        profilePath: profilePath,
      );
}

/// 相似推荐分页 DTO（append_to_response=similar 返回 {page, results: [...]}）
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SimilarMoviePageDto {
  const SimilarMoviePageDto({required this.page, required this.results});

  final int page;
  final List<SimilarMovieDto> results;

  factory SimilarMoviePageDto.fromJson(Map<String, dynamic> json) =>
      _$SimilarMoviePageDtoFromJson(json);
}

/// 相似推荐里的单条电影（字段比列表的 MovieDto 少 genreIds）
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SimilarMovieDto {
  const SimilarMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;

  factory SimilarMovieDto.fromJson(Map<String, dynamic> json) =>
      _$SimilarMovieDtoFromJson(json);

  /// DTO → Domain Movie（相似推荐复用列表卡片，genreIds 填空数组）
  Movie toMovie() => Movie(
        id: id,
        title: title,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
        genreIds: const [],
      );
}
