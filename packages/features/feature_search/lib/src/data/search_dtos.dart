import 'package:json_annotation/json_annotation.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';

part 'search_dtos.g.dart';

/// =============================================================================
/// SearchDtos —— 搜索模块私有 DTO（对标 feature-search 的 SearchDtos.kt）
/// =============================================================================
///
/// 调用：GET /search/movie?query=xxx&page=1
///   TMDB 搜索端点，query 是关键词，page 分页。
///   响应结构与 /movie/popular 一致（page/results/total_pages/total_results）。

/// 搜索结果单条电影（字段与列表 MovieDto 一致，但搜索模块自带避免跨包依赖）
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SearchMovieDto {
  const SearchMovieDto({
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
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;

  factory SearchMovieDto.fromJson(Map<String, dynamic> json) =>
      _$SearchMovieDtoFromJson(json);

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

/// 搜索响应分页（{ page, results, total_pages, total_results }）
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SearchResponseDto {
  const SearchResponseDto({required this.page, required this.results});

  final int page;
  final List<SearchMovieDto> results;

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseDtoFromJson(json);
}
