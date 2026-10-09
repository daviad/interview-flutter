import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'tmdb_client.dart';
import 'tmdb_constants.dart';

/// =============================================================================
/// 网络层 Provider 集合（DI 装配点，对标 Android data-api 的 DataApiModule/TmdbModule）
/// =============================================================================
///
/// Riverpod 概念速记（🍎 对照 Koin/Hilt）：
///   `Provider<T>` = 单例工厂（等价 Koin `single<T> { ... }` / Hilt @Provides）
///   ref.watch(x) = 取依赖；x 变化时本 Provider 自动重建（等价 DI 图联动）
///   ProviderScope(overrides: [x.overrideWithValue(v)]) = 装配层替换实现
///     （等价 Hilt 测试模块 / Koin module override）

/// -----------------------------------------------------------------------------
/// ① tmdbApiKeyProvider —— TMDB Bearer access token 契约（= Hilt @Named("tmdb_api_key") String）
/// -----------------------------------------------------------------------------
///
/// 注意：Provider 名沿用历史叫 `tmdbApiKeyProvider`，但它实际承载的是
/// TMDB v4 **Bearer access token**（一个 JWT），由 `--dart-define=TMDB_API_KEY=<jwt>`
/// 注入。TmdbClient 会把它放进 `Authorization: Bearer <token>` header 鉴权
/// （不再用 v3 的 ?api_key=xxx 查询参数）。
///
/// 默认抛 UnimplementedError：强制壳工程在 ProviderScope(overrides:) 里
/// 用 --dart-define 读到的 token 覆写它。
///
/// 为什么不让它直接读 String.fromEnvironment？
///   因为 core_network 是基础层，token 属于「宿主编译配置」（Android 版只有
///   app 模块能看 BuildConfig）。由壳注入、基础层声明契约，层级才不反。
///
/// 🍎 UIKit 类比：Service 容器里注册一个 apiKey: String 的协议，
///    AppDelegate 启动时从 .xcconfig 注入；没人注册就 fatalError（同这里）。
final Provider<String> tmdbApiKeyProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'tmdbApiKeyProvider 未装配：请在 ProviderScope(overrides:) 中注入 '
    'tmdbApiKeyProvider.overrideWithValue(const String.fromEnvironment(\'TMDB_API_KEY\'))',
  );
});

/// -----------------------------------------------------------------------------
/// ② dioProvider —— Dio（HTTP 客户端）单例
/// -----------------------------------------------------------------------------
///
/// 对标 Android 版的 HttpClientFactory（OkHttp engine + 超时 + 日志）。
/// Dio 等价于 Ktor/Retrofit + OkHttp 的合体。
///
/// 【⚠️ 代理坑 —— 必读（与 KMP 版「CIO 不读代理」同源问题）】
///   Dart 的 HttpClient（Dio 在原生平台的底层）默认**不读取 Android 系统代理**，
///   直接连 api.themoviedb.org 会 DNS 失败（国内网络）。所以 debug 模式下
///   显式指定代理：
///     - Android 模拟器：宿主机是 10.0.2.2:65533
///       （模拟器里的 10.0.2.2 = 宿主机 loopback；65533 端口由宿主机
///         netsh portproxy 转发到本地 Nano 代理 65532，和 KMP 工程同一套）
///     - Windows 桌面：本机代理直接是 127.0.0.1:65532
///   release 模式不设置代理（用户网络环境正常）。
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // 超时 15s：对齐 Android 工程「调试期快速失败」约定，
      // 不使用 Long.MAX_VALUE 防止挂死排查困难。
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    // 请求/响应日志（= Ktor Logging plugin / OkHttp HttpLoggingInterceptor）
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: false,
        compact: true,
      ),
    );

    // 显式代理（见上面的长注释）。IOHttpClientAdapter 是原生平台专用适配器。
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        const proxyHost = String.fromEnvironment('TMDB_PROXY_HOST', defaultValue: '');
        final proxy = proxyHost.isNotEmpty
            ? proxyHost // 允许 --dart-define=TMDB_PROXY_HOST=host:port 覆盖
            : Platform.isAndroid
                ? '10.0.2.2:65533' // Android 模拟器 → 宿主机 portproxy
                : '127.0.0.1:65532'; // Windows 桌面直连本机代理
        debugPrint('[core_network] debug 代理启用: PROXY $proxy');
        client.findProxy = (uri) => 'PROXY $proxy';
        return client;
      },
    );
  }

  return dio;
});

/// -----------------------------------------------------------------------------
/// ③ tmdbClientProvider —— 端点无关的 TMDB 门面客户端
/// -----------------------------------------------------------------------------
///
/// 收敛 baseUrl + accessToken + 默认语言（= TmdbModule.provideTmdbClient）。
/// 各 feature 注入本客户端后只描述业务端点，不关心鉴权细节。
/// accessToken 由 tmdbApiKeyProvider 提供（承载 Bearer JWT，见其注释）。
final Provider<TmdbClient> tmdbClientProvider = Provider<TmdbClient>((ref) {
  return TmdbClient(
    dio: ref.watch(dioProvider),
    baseUrl: TmdbConstants.baseUrl,
    accessToken: ref.watch(tmdbApiKeyProvider),
    defaultLanguage: TmdbConstants.defaultLanguage,
  );
});
