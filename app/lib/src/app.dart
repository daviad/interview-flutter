import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviely_core_ui/moviely_core_ui.dart';

import 'router/shell_router.dart';

/// =============================================================================
/// MovielyApp —— 根 Widget（对标 MovielyApp() @Composable 应用根）
/// =============================================================================
///
/// MaterialApp.router 是 go_router 的挂载点：
/// 路由表不是手写在这，而是从 shellRouterProvider 取（该 Provider 聚合了
/// 所有 feature 贡献的 routes）。
///
/// 🍎 UIKit 类比：SceneDelegate 里 window.rootViewController =
///    一个由各模块注册的路由表构建的导航容器。
class MovielyApp extends ConsumerWidget {
  const MovielyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(shellRouterProvider);
    return MaterialApp.router(
      title: 'Moviely',
      theme: MovielyTheme.light,
      darkTheme: MovielyTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
