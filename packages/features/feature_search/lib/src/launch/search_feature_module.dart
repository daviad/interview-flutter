import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';

import '../presentation/search_screen.dart';

/// =============================================================================
/// SearchFeatureModule —— 搜索模块的「装配入口」（对标 SearchModuleLifecycle.kt）
/// =============================================================================
///
/// 贡献路由 '/search'（底部 tab 路径之一，被壳的 StatefulShellRoute 接到
/// 第二个 branch）。
class SearchFeatureModule implements FeatureModule {
  const SearchFeatureModule();

  @override
  Future<void> onCreate() async {
    debugPrint('[SearchFeatureModule] feature-search 模块已装配 onCreate()');
  }

  @override
  void onTerminate() {}

  @override
  AppRoute get startRoute => const SearchRoute();

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: const SearchRoute().path, // '/search'
          builder: (context, state) => const SearchScreen(),
        ),
      ];
}
