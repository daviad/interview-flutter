import 'detail_dtos.dart';

/// =============================================================================
/// DetailApi —— 详情业务端点契约（对标 feature-detail 的 DetailApi.kt）
/// =============================================================================
///
/// 纯抽象接口，归 feature 私有（不放 core_network —— 基础层不认识业务端点）。
///
/// 🍎 UIKit 类比：protocol DetailServiceProtocol {
///   func movieDetail(id: Int) async throws -> MovieDetailDto
/// }
abstract interface class DetailApi {
  /// GET /movie/{movieId}?append_to_response=credits,similar
  /// 一次返回详情 + 演员表 + 相似推荐（TMDB 批量请求）。
  Future<MovieDetailDto> getMovieDetail(int movieId);
}
