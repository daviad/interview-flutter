import 'package:moviely_core_network/moviely_core_network.dart';

import 'search_api.dart';
import 'search_dtos.dart';

/// =============================================================================
/// SearchApiClient —— SearchApi 的实现（对标 SearchApiClient.kt）
/// =============================================================================
class SearchApiClient implements SearchApi {
  SearchApiClient(this._client);

  final TmdbClient _client;

  @override
  Future<SearchResponseDto> searchMovies(String query, {int page = 1}) {
    return _client.get(
      '/search/movie',
      params: {'query': query, 'page': page},
      fromJson: SearchResponseDto.fromJson,
    );
  }
}
