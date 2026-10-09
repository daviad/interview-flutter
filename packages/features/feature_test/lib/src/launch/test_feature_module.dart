import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';

import '../presentation/test_screen.dart';

/// =============================================================================
/// TestFeatureModule —— test 模块的「装配入口」
/// =============================================================================
///
/// 贡献路由 '/test'（底部 tab 路径之一，被壳的 StatefulShellRoute 接到
/// 第四个 branch）。它如何被壳发现：
///   app_launch（聚合器）在 bootstrapOverrides 里把本类实例加入
///   featureModulesProvider 的列表；壳只拿到 `List<FeatureModule>`，
///   不知道具体类型，也不 import 本包。
///
/// 🍎 UIKit 类比：BeeHive 的 BHModule 子类，注册后由 AppDelegate 统一
///    调 setUp，并向中央 Router 注册自己的 URL 路由。
class TestFeatureModule implements FeatureModule {
  const TestFeatureModule();

  @override
  Future<void> onCreate() async {
    debugPrint('[TestFeatureModule] feature-test 模块已装配 onCreate()');
  }

  @override
  void onTerminate() {}

  @override
  AppRoute get startRoute => const TestRoute();

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: const TestRoute().path, // '/test' —— 对应底部第 4 个 tab
      builder: (context, state) => const TestScreen(),
    ),
  ];
}
