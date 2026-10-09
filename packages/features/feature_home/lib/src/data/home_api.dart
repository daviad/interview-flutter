import 'home_dtos.dart';

/// =============================================================================
/// HomeApi —— 首页业务端点契约（对标 feature-home 的 HomeApi.kt）
/// =============================================================================
///
/// 纯抽象接口，归 feature 私有（不放 core_network —— 基础层不认识业务端点）。
///
/// 🍎 UIKit 类比：protocol HomeServiceProtocol {
///   func popular(page: Int) async throws -> MovieResponseDto
/// }
abstract interface class HomeApi {
  /// GET /movie/popular?page={page} 热门电影
  Future<MovieResponseDto> getPopularMovies({int page});

  /// GET /movie/now_playing?page={page} 正在上映
  Future<MovieResponseDto> getNowPlayingMovies({int page});
}
