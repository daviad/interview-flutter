import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';

import 'main_shell.dart';

/// =============================================================================
/// shellRouterProvider —— 壳导航聚合器（对标 MovielyNavHost.  kt）
/// =============================================================================
///
/// 遍历 featureModulesProvider，把各 feature 贡献的 routes 分类：
///   - **tab 路由**（path ∈ [AppRoute.tabs] 各路由的 path：
///     '/' '/search' '/favorite' '/test'）
///     → 挂到 [StatefulShellRoute.indexedStack] 的对应 branch，作为底部 tab
///   - **非 tab 压栈路由**（如 '/detail/:id'）→ 挂到根层，进入后隐藏底栏
///
/// 【可插拔验证点】
///   - 拔掉 feature_search：search tab 显示 _NoModulePage 占位（"未接入搜索模块"），
///     其他 tab 与 detail 照常工作。
///   - 空列表（bootstrapOverrides 一个模块都没注册）→ 四个 tab 都显示占位页，
///     App 仍可编译运行。
///
/// 🍎 UIKit 类比：UITabBarController + 每个 tab 的 VC 由各模块注册；
///    非 tab 页用 push(present) 压栈，不进 tab 容器。
final Provider<GoRouter> shellRouterProvider = Provider<GoRouter>((ref) {
  final modules = ref.watch(featureModulesProvider);

  // tab 注册表来自 AppRoute.tabs：哪些路由是 tab 及其顺序（壳级关注点）
  final tabPaths = AppRoute.tabs.map((r) => r.path).toList();
  final tabPathSet = tabPaths.toSet();

  // 按 path 分类各 feature 贡献的路由
  final tabRouteMap = <String, GoRoute>{};
  final otherRoutes = <RouteBase>[];
  for (final module in modules) {
    for (final route in module.routes) {
      if (route is GoRoute && tabPathSet.contains(route.path)) {
        tabRouteMap[route.path] = route;
      } else {
        otherRoutes.add(route);
      }
    }
  }

  return GoRouter(
    initialLocation: const HomeRoute().path,
    routes: [
      // 底部 tab shell：home / search / favorite / test 四个 branch
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          for (final tab in AppRoute.tabs)
            StatefulShellBranch(
              routes: [
                // 找不到对应 feature 的 tab 路由 → 占位页（可插拔兜底）
                tabRouteMap[tab.path] ??
                    GoRoute(
                      path: tab.path,
                      builder: (context, state) =>
                          _NoModulePage(path: tab.path),
                    ),
              ],
            ),
        ],
      ),
      // 非 tab 压栈路由（detail 等）：进入后隐藏底栏
      ...otherRoutes,
    ],
  );
});

/// 空壳占位页（某 tab 未接入对应 feature 时显示）
class _NoModulePage extends StatelessWidget {
  const _NoModulePage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moviely')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '路径 $path 未接入任何模块\n请在 app_launch 的 bootstrapOverrides '
            '中注册对应 FeatureModule',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
