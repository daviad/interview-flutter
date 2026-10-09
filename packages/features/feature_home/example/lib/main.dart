import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviely_core_network/moviely_core_network.dart';
import 'package:moviely_core_ui/moviely_core_ui.dart';
import 'package:moviely_feature_home/moviely_feature_home.dart';

/// =============================================================================
/// feature_home 独立调试 App（对标 Android 版 feature 模块的 standalone 源集）
/// =============================================================================
///
/// 不经过壳与聚合器：直接挂 HomeScreen + 自带 ProviderScope。
/// 单独跑这个 app 就能开发调试首页，无需编译整个壳工程。
///
/// 运行方式：
///   flutter run --dart-define=TMDB_API_KEY=你的key
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚙️ debug 全局 HTTP 代理：让 cached_network_image 等非 Dio 请求也走代理
  configureDebugHttpOverrides();

  const apiKey = String.fromEnvironment('TMDB_API_KEY');

  runApp(
    ProviderScope(
      overrides: [
        if (apiKey.isNotEmpty) tmdbApiKeyProvider.overrideWithValue(apiKey),
      ],
      child: const _StandaloneApp(),
    ),
  );
}

class _StandaloneApp extends StatelessWidget {
  const _StandaloneApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'feature_home standalone',
      theme: MovielyTheme.light,
      darkTheme: MovielyTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(), // 直接挂 feature 页面
    );
  }
}
