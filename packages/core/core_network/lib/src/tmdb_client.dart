import 'package:dio/dio.dart';

/// =============================================================================
/// TmdbClient —— 通用 TMDB 客户端（端点无关，业务方只传 path）
/// =============================================================================
///
/// 对标 Android 工程 data-api 的 `TmdbClient`（Ktor 版）。
///
/// 【基础层与业务层的分工】
///   本类（基础层）只负责「怎么发请求」：
///     - baseUrl 拼接、Bearer 鉴权、默认 language —— 全 App 统一
///     - 泛型 `get<T>()` —— 不认识任何业务端点
///   各 feature（业务层）负责「请求什么」：
///     feature_home 定义自己的 HomeApi（/movie/popular、/movie/now_playing）
///
/// 🍎 UIKit 类比：AFHTTPSessionManager / URLSession 封装（基础层），
///    各业务自己写 APIService + 端点常量（业务层）。
///
/// 【鉴权方式 —— TMDB v4 Bearer Token】
///   本工程使用 TMDB v4 access token（一个 JWT），通过 HTTP header 鉴权：
///     `Authorization: Bearer <token>`
///   ❌ 不再用 v3 的 ?api_key=xxx 查询参数（旧写法把 JWT 塞进 api_key 字段，
///      TMDB 会返回 401，因为 api_key 字段期望的是 32 位 v3 key 而非 JWT）。
///   token 仍通过 `--dart-define=TMDB_API_KEY=<jwt>` 注入（define 名沿用历史，
///   实际承载的是 Bearer access token，见 tmdb_constants.dart 的数据链路说明）。
///
/// 【Dart 泛型与 fromJson】
///   Dart 泛型不擦除（运行时保留 T），但 Dio 不知道怎么把 Map 变成业务对象，
///   所以调用方必须显式传入 `fromJson: MovieResponseDto.fromJson`
///   （等价 Ktor `body<T>()` 依赖 kotlinx.serialization 反射/插件）。
class TmdbClient {
  TmdbClient({
    required Dio dio,
    required String baseUrl,
    required String accessToken,
    required String defaultLanguage,
  }) : _dio = dio,
       _baseUrl = baseUrl,
       _accessToken = accessToken,
       _defaultLanguage = defaultLanguage;

  final Dio _dio;
  final String _baseUrl;
  final String _accessToken;
  final String _defaultLanguage;

  /// 泛型 GET：拼接 baseUrl + path，自动附带 Bearer 鉴权与默认 language。
  ///
  /// - [path]  端点路径，以 '/' 开头（如 '/movie/popular'），由业务方传入
  /// - [params] 额外查询参数（page、query 等）
  /// - [fromJson] JSON(Map) → T 的反序列化函数（json_serializable 生成）
  ///
  /// 异常直接向上抛 DioException，由调用方（Controller）catch 并转成错误状态。
  ///
  /// 🍎 UIKit 类比：
  ///   `func get<T: Decodable>(_ path: String, ...) async throws -> T`
  Future<T> get<T>(
    String path, {
    Map<String, dynamic> params = const {},
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    // 查询参数只放业务参数 + 默认 language；鉴权走 header，不再塞 query。
    // 同 key 覆盖：调用方 params 后放，可覆盖默认 language。
    final queryParameters = <String, dynamic>{
      'language': _defaultLanguage,
      ...params,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl$path',
      queryParameters: queryParameters,
      options: Options(
        headers: {
          // TMDB v4 鉴权：Bearer access token
          // （= Authorization: Bearer <token>，对标旧版 v3 ?api_key=xxx 已废弃）
          'Authorization': 'Bearer $_accessToken',
        },
      ),
    );

    return fromJson(response.data!);
  }
}
