import 'package:moviely_core_network/moviely_core_network.dart';

import 'home_api.dart';
import 'home_dtos.dart';

/// =============================================================================
/// HomeApiClient —— HomeApi 的实现（对标 HomeApiClient.kt）
/// =============================================================================
///
/// 只描述「端点路径 + 业务参数」，怎么发请求/鉴权/拼 baseUrl 全由 TmdbClient
/// （core_network 基础层）负责。
///
/// 🍎 UIKit 类比：HomeService: HomeServiceProtocol，内部持有 APIClient 发请求。
class HomeApiClient implements HomeApi {
  HomeApiClient(this._client);

  final TmdbClient _client;

  @override
  Future<MovieResponseDto> getPopularMovies({int page = 1}) {
    return _client.get(
      '/movie/popular',
      params: {'page': page},
      fromJson: MovieResponseDto.fromJson,
    );
  }

  @override
  Future<MovieResponseDto> getNowPlayingMovies({int page = 1}) {
    return _client.get(
      '/movie/now_playing',
      params: {'page': page},
      fromJson: MovieResponseDto.fromJson,
    );
  }
}
