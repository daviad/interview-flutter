import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';

import '../presentation/home_screen.dart';

/// =============================================================================
/// HomeFeatureModule —— 首页模块的「装配入口」（对标 HomeModuleLifecycle.kt）
/// =============================================================================
///
/// 同时承担两个协议职责（和 Android 版一样合并在一个类里）：
///   ① FeatureModule.onCreate：App 启动时被壳统一遍历调用（= ModuleLifecycle）
///   ② FeatureModule.routes ：向壳 GoRouter 贡献自己的路由表（= ModuleNavigator）
///
/// 【它如何被壳发现？】
///   app_launch（聚合器）在 bootstrapOverrides 里把本类实例加入
///   featureModulesProvider 的 override 列表（= Hilt @Binds @IntoSet 贡献）。
///   壳只拿到 `List<FeatureModule>`，不知道具体类型，也不 import 本包。
///
/// 🍎 UIKit 类比：BeeHive 的 BHModule 子类，注册后由 AppDelegate 统一
///    调 modSetUp，并向中央 Router 注册自己的 URL 路由。
class HomeFeatureModule implements FeatureModule {
  const HomeFeatureModule();

  @override
  Future<void> onCreate() async {
    // 首页暂无 SDK 需要初始化（对标 Android 版打一条日志证明已装配）
    debugPrint('[HomeFeatureModule] feature-home 模块已装配 onCreate()');
  }

  @override
  void onTerminate() {}

  @override
  AppRoute get startRoute => const HomeRoute();

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: const HomeRoute().path, // '/' —— 壳 GoRouter 的 initialLocation
      builder: (context, state) => const HomeScreen(),
    ),
  ];
}
