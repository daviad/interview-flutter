import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// =============================================================================
/// MainShell —— 底部 tab 容器（对标 MovielyNavHost 的 Scaffold.bottomBar + NavigationBar）
/// =============================================================================
///
/// 包裹 [StatefulShellRoute.indexedStack] 的 navigationShell：
///   - 底部 NavigationBar 四个 tab（首页/搜索/收藏/Test）
///   - 点击切换 branch（= Compose NavigationBar 的 navigate(route)）
///   - 当前 tab 的导航栈由 navigationShell 管理（保留各 tab 状态）
///
/// 【tab 顺序与 [AppRoute.tabs] 一一对应】
///   index 0 = home  (Icons.home, '首页')
///   index 1 = search (Icons.search, '搜索')
///   index 2 = favorite (Icons.favorite, '收藏')
///   index 3 = test (Icons.science, 'Test')
///
///   改顺序需同步改 AppRoute.tabs 和本文件 _tabs。
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_TabSpec>[
    _TabSpec(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首页'),
    _TabSpec(icon: Icons.search_outlined, selectedIcon: Icons.search, label: '搜索'),
    _TabSpec(icon: Icons.favorite_border, selectedIcon: Icons.favorite, label: '收藏'),
    _TabSpec(icon: Icons.science_outlined, selectedIcon: Icons.science, label: 'Test'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // 当前 branch 的页面
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // 切回已访问 tab 时恢复初始 location（对标 Compose saveState/restoreState）
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
