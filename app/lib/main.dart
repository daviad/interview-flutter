import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviely_app_launch/moviely_app_launch.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';
import 'package:moviely_core_network/moviely_core_network.dart';

import 'src/app.dart';

/// =============================================================================
/// 壳工程入口（对标 component-moviely 的 MovielyApp.kt / App.onCreate）
/// =============================================================================
///
/// 启动流程（对照 Android 版 Application.onCreate）：
///   ① 读编译期注入的 API key（--dart-define=TMDB_API_KEY=xxx
///      = Android 的 BuildConfig.TMDB_API_KEY，由 local.properties 注入）
///   ② 建 DI 容器（ProviderContainer = Hilt 组件图）：
///      - 网络配置（api key）由壳注入给 core_network
///      - bootstrapOverrides（同步：featureModules）+
///        buildAsyncBootstrapOverrides()（异步：SharedPreferences→favoriteRepo）
///        都来自 app_launch 聚合器（壳零 feature import，符合铁律 1）
///   ③ 遍历 featureModulesProvider 分发 onCreate（= 遍历 ModuleLifecycle）
///   ④ runApp 挂根 Widget
///
/// 注意：本文件 import 不到任何 feature 包 —— feature 对壳完全透明
/// （favoriteRepository 注入由 app_launch 聚合器内部完成）。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚙️ debug 全局 HTTP 代理：让 cached_network_image 等非 Dio 请求也走代理
  // （图片走 Flutter 原生 HttpClient，不受 dioProvider 的 IOHttpClientAdapter 影响）
  configureDebugHttpOverrides();

  // ① API key 只通过编译参数传入，不写进源码（key 为空则 core_network 抛
  //   UnimplementedError 并提示如何注入，= Hilt 缺失 binding 的快速失败）
  const apiKey = String.fromEnvironment('TMDB_API_KEY');

  // ② 异步 override：SharedPreferences→favoriteRepositoryProvider
  //    （聚合器内部 await SharedPreferences.getInstance，壳零 feature import）
  final asyncOverrides = await buildAsyncBootstrapOverrides();

  // ③ DI 容器：override 是 Riverpod 的「装配层替换」机制
  final container = ProviderContainer(
    overrides: [
      if (apiKey.isNotEmpty) tmdbApiKeyProvider.overrideWithValue(apiKey),
      ...bootstrapOverrides, // 同步：featureModulesProvider ← 各 FeatureModule
      ...asyncOverrides, // 异步：favoriteRepositoryProvider ← FavoriteRepository(prefs)
    ],
  );

  // ④ 生命周期分发（= MovielyApp.onCreate: modules.forEach { it.onCreate() }）
  for (final module in container.read(featureModulesProvider)) {
    await module.onCreate();
  }

  // ⑤ UncontrolledProviderScope：把手动创建的容器挂到 Widget 树
  // （= HiltAndroidApp 注入应用级组件图）
  runApp(
    UncontrolledProviderScope(container: container, child: const MovielyApp()),
  );
}
