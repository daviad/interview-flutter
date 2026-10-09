import 'package:moviely_core_network/moviely_core_network.dart';

import 'detail_api.dart';
import 'detail_dtos.dart';

/// =============================================================================
/// DetailApiClient —— DetailApi 的实现（对标 DetailApiClient.kt）
/// =============================================================================
///
/// 只描述「端点路径 + 业务参数」，怎么发请求/鉴权/拼 baseUrl 全由 TmdbClient
/// （core_network 基础层）负责。
class DetailApiClient implements DetailApi {
  DetailApiClient(this._client);

  final TmdbClient _client;

  @override
  Future<MovieDetailDto> getMovieDetail(int movieId) {
    return _client.get(
      '/movie/$movieId',
      // append_to_response：TMDB 批量请求参数，一次拿详情 + credits + similar
      // （多个端点的响应合并进同一个 JSON，对标 Kotlin 版的 append_to_response）
      params: const {'append_to_response': 'credits,similar'},
      fromJson: MovieDetailDto.fromJson,
    );
  }
}
