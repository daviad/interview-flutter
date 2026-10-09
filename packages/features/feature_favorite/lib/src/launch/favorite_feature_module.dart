import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';

import '../presentation/favorite_screen.dart';

/// =============================================================================
/// FavoriteFeatureModule —— 收藏模块的「装配入口」
/// （对标 FavoriteModuleLifecycle.kt）
/// =============================================================================
///
/// 贡献路由 '/favorite'（底部 tab 路径之一，被壳的 StatefulShellRoute 接到
/// 第三个 branch）。
class FavoriteFeatureModule implements FeatureModule {
  const FavoriteFeatureModule();

  @override
  Future<void> onCreate() async {
    debugPrint('[FavoriteFeatureModule] feature-favorite 模块已装配 onCreate()');
  }

  @override
  void onTerminate() {}

  @override
  AppRoute get startRoute => const FavoriteRoute();

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: const FavoriteRoute().path, // '/favorite'
          builder: (context, state) => const FavoriteScreen(),
        ),
      ];
}
