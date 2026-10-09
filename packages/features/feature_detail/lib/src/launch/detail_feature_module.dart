import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';

import '../presentation/detail_screen.dart';

/// =============================================================================
/// DetailFeatureModule —— 详情模块的「装配入口」（对标 DetailModuleLifecycle.kt）
/// =============================================================================
///
/// 贡献路由 '/detail/:id'（压栈路由，不在底部 tab shell 内，进入后隐藏底栏）。
/// feature_home 点击海报 context.push('/detail/123') → 本模块 builder 承接。
class DetailFeatureModule implements FeatureModule {
  const DetailFeatureModule();

  @override
  Future<void> onCreate() async {
    debugPrint('[DetailFeatureModule] feature-detail 模块已装配 onCreate()');
  }

  @override
  void onTerminate() {}

  /// 详情页没有真正的「起始路由」（必须带 movieId），此处仅为协议占位。
  @override
  AppRoute get startRoute => const DetailRoute(0);

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: DetailRoute.pathTemplate, // '/detail/:id' —— 注册用模板
          // 从 path 参数取 movieId，传给 DetailScreen 的 family provider
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return DetailScreen(movieId: id);
          },
        ),
      ];
}
