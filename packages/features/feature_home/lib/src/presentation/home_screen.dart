import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';
import 'package:moviely_core_ui/moviely_core_ui.dart';

import 'home_controller.dart';
import 'home_state.dart';

/// =============================================================================
/// HomeScreen —— 首页主入口（对标 HomeScreen.kt）
/// =============================================================================
///
/// ConsumerWidget = 能读 Provider 的 Widget（等价 Compose 里 collectAsState）。
///   ref.watch(provider)  : 订阅状态，状态变化自动 rebuild（= collectAsStateWithLifecycle）
///   ref.read(provider)   : 只取值不订阅（回调里用，= 一次性取 ViewModel）
///   ref.listen(provider) : 监听变化做副作用（Snackbar/导航，= LaunchedEffect 收 Effect）
///
/// 🍎 UIKit 类比：UIViewController 里订阅 ViewModel 的 state 闭包回调 reloadData；
/// 🍎 SwiftUI 类比：struct HomeView: View { @StateObject var vm = ... } body 随状态重建。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);

    // 一次性副作用：刷新消息 → Snackbar（对标 Channel<HomeEffect> / LaunchedEffect）
    ref.listen<HomeState>(homeControllerProvider, (previous, next) {
      final message = switch (next) {
        HomeSuccess(:final refreshMessage?) when refreshMessage.isNotEmpty =>
          refreshMessage,
        _ => null,
      };
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Moviely')),
      body: switch (state) {
        // 三态穷尽匹配（= Compose 的 when (val s = state)）
        HomeLoading() => const LoadingView(),
        HomeError(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(homeControllerProvider.notifier).refresh(),
          ),
        HomeSuccess success => _HomeContent(state: success),
      },
    );
  }
}

/// =============================================================================
/// _HomeContent —— 首页内容（对标 HomeContent()）
/// =============================================================================
///
/// 布局：垂直 ListView（= LazyColumn）内嵌：
///   「热门电影」标题 + 横向 ListView.builder（= LazyRow，海报卡片）
///   「正在上映」标题 + 纵向电影项（= LazyColumn items）
/// 外层 RefreshIndicator 提供下拉刷新（= PullToRefreshBox）。
class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.state});

  final HomeSuccess state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      // isRefreshing 由 RefreshIndicator 内部 future 管理：
      // onRefresh 返回的 Future 完成前一直显示转圈。
      onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const SectionTitle('热门电影'),
          if (state.popularMovies.isEmpty)
            const EmptyState(message: '暂无热门电影')
          else
            SizedBox(
              height: 232, // 海报 180 + 标题/卡片间距，撑出横向列表高度
              child: ListView.builder(
                scrollDirection: Axis.horizontal, // = LazyRow（横向滑动）
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.popularMovies.length,
                itemBuilder: (context, index) {
                  final movie = state.popularMovies[index];
                  return Container(
                    width: 128,
                    margin: const EdgeInsets.only(right: 12),
                    child: MovieCard(
                      movie: movie,
                      onTap: () => _openDetail(context, movie),
                    ),
                  );
                },
              ),
            ),
          const SectionTitle('正在上映'),
          if (state.nowPlayingMovies.isEmpty)
            const EmptyState(message: '暂无正在上映的电影')
          else
            ...state.nowPlayingMovies.map(
              (movie) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: MovieListTile(
                  movie: movie,
                  onTap: () => _openDetail(context, movie),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 跨 feature 导航：只走 core_launch 的路径契约，不 import 详情页
  /// （= Android 侧 NavController.navigate("detail/$id") 的占位契约）。
  /// 用 [DetailRoute] sealed 子类编译期约束 id 类型，再 .path 序列化给 GoRouter。
  void _openDetail(BuildContext context, Movie movie) {
    context.push(DetailRoute(movie.id).path);
  }
}
