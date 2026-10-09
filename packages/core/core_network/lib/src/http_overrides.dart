import 'dart:io';

import 'package:flutter/foundation.dart';

/// =============================================================================
/// 全局 HTTP 代理覆盖（让非 Dio 的网络请求也走代理）
/// =============================================================================
///
/// 【为什么需要这个？】
///   `dioProvider` 里配的代理只对 **Dio 发出的请求**生效（API 接口）。
///   但图片加载用的是 `cached_network_image` → Flutter 的 `Image.network` →
///   底层 `HttpClient`，**不走 Dio**。所以 `image.tmdb.org` 在国内会被墙，
///   表现为海报全加载失败、显示 broken_image 图标。
///
///   解决：设置 `HttpOverrides.global`，所有 Flutter 原生 `HttpClient`
///   （包括图片加载）都走同一个代理。Dio 因为有自己的 `IOHttpClientAdapter`
///   显式 `createHttpClient`，不会受影响——两套代理配置互不干扰。
///
///   🍎 UIKit 类比：相当于在 `NSURLSessionConfiguration.defaultConfiguration`
///   上设 `connectionProxyDictionary`，全局影响所有 `URLSession` 共享配置。
///
/// 【调用时机】
///   必须在 `WidgetsFlutterBinding.ensureInitialized()` 之后、`runApp` 之前
///   调一次。release 模式自动跳过（用 `kDebugMode` 判断）。
class ProxyHttpOverrides extends HttpOverrides {
  ProxyHttpOverrides(this._proxy);

  final String _proxy;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY $_proxy';
    return client;
  }
}

/// 在 debug 模式设置全局 HTTP 代理覆盖（图片等非 Dio 请求用）。
///
/// 代理 host:port 解析顺序（与 [dioProvider] 保持一致）：
///   1. `--dart-define=TMDB_PROXY_HOST=host:port` 覆盖
///   2. Android 模拟器：`10.0.2.2:65533`（模拟器里的 10.0.2.2 = 宿主机 loopback；
///      65533 由宿主机 netsh portproxy 转发到本地 Nano 代理 65532）
///   3. Windows 桌面：`127.0.0.1:65532`（本机代理直连）
/// release 模式不设置代理（用户网络环境正常）。
void configureDebugHttpOverrides() {
  if (!kDebugMode) return;

  const proxyHost = String.fromEnvironment('TMDB_PROXY_HOST', defaultValue: '');
  final proxy = proxyHost.isNotEmpty
      ? proxyHost
      : Platform.isAndroid
          ? '10.0.2.2:65533'
          : '127.0.0.1:65532';

  HttpOverrides.global = ProxyHttpOverrides(proxy);
  debugPrint('[core_network] 全局 HttpOverrides 代理启用: PROXY $proxy '
      '（覆盖 cached_network_image 等非 Dio 请求）');
}
