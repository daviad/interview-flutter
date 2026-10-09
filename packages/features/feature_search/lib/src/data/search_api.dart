import 'search_dtos.dart';

/// =============================================================================
/// SearchApi —— 搜索业务端点契约（对标 feature-search 的 SearchApi.kt）
/// =============================================================================
abstract interface class SearchApi {
  /// GET /search/movie?query={query}&page={page}
  Future<SearchResponseDto> searchMovies(String query, {int page});
}
