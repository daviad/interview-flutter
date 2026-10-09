import 'package:json_annotation/json_annotation.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';

part 'home_dtos.g.dart';

/// =============================================================================
/// HomeDtos —— 首页模块私有 DTO（对标 feature-home 的 HomeDtos.kt）
/// =============================================================================
///
/// 【DTO 与 Domain 为什么分开？】
///   DTO（Data Transfer Object）= 服务器 JSON 的 1:1 映射，字段/命名跟着接口走，
///   脏（可空字段多、snake_case）；Domain Model 是干净的业务实体（Movie）。
///   分层后接口变动只影响 data 层，UI 只认 Movie。
///
/// 【json_serializable = GSON/kotlinx.serialization 的 Dart 版】
///   @JsonSerializable 标注 + build_runner 生成 home_dtos.g.dart（= KSP 生成代码）；
///   fieldRename: snakeCase 让 poster_path 自动映射 posterPath，不用逐字段 @JsonKey。
///
/// 🍎 UIKit 类比：Decodable 的 struct + JSONDecoder；
/// 🍎 SwiftUI 类比：Codable Model  +  extension 里转 Domain struct。

/// TMDB 列表接口的单条电影 DTO（/movie/popular、/movie/now_playing 的元素）。
///
/// createToJson: false —— 本工程只做反序列化（读接口），不生成 toJson，
/// 避免生成死代码告警。
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class MovieDto {
  const MovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
  });

  final int id;
  final String title;
  final String overview;

  /// 可空：少数电影无海报（对应 Kotlin String?）
  final String? posterPath;
  final String? backdropPath;

  /// TMDB 评分。json_serializable 生成 (json['vote_average'] as num).toDouble()，
  /// 兼容接口返回整数（如 8）的情况。
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;

  /// json_serializable 生成的反序列化工厂（g.dart 中实现）。
  factory MovieDto.fromJson(Map<String, dynamic> json) =>
      _$MovieDtoFromJson(json);

  /// DTO → Domain 映射（对标 Kotlin HomeViewModel 里的 MovieDto.toMovie()）。
  Movie toMovie() => Movie(
    id: id,
    title: title,
    overview: overview,
    posterPath: posterPath,
    backdropPath: backdropPath,
    voteAverage: voteAverage,
    releaseDate: releaseDate,
    genreIds: genreIds,
  );
}

/// TMDB 分页列表响应（{ page, results: [...], total_pages ... }）。
/// 本工程只用 page + results，其余字段按需再加。
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class MovieResponseDto {
  const MovieResponseDto({required this.page, required this.results});

  final int page;
  final List<MovieDto> results;

  factory MovieResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MovieResponseDtoFromJson(json);
}
