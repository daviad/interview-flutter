import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';
import 'package:moviely_core_ui/moviely_core_ui.dart';

import 'favorite_controller.dart';
import 'favorite_state.dart';

/// =============================================================================
/// FavoriteScreen —— 收藏页入口（对标 FavoriteScreen.kt）
/// =============================================================================
///
/// 布局：列表（MovieListTile + 右侧删除按钮）+ 空态。
/// 列表项点击跳详情，删除按钮调 controller.remove 后自动刷新。
class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: switch (state) {
        FavoriteLoading() => const LoadingView(),
        FavoriteError(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(favoriteControllerProvider.notifier).refresh(),
          ),
        FavoriteSuccess(:final movies) => movies.isEmpty
            ? const EmptyState(message: '还没有收藏的电影\n去详情页点收藏吧')
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(favoriteControllerProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: MovieListTile(
                              movie: movie,
                              onTap: () => context.push(
                                DetailRoute(movie.id).path,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: '取消收藏',
                            onPressed: () => ref
                                .read(favoriteControllerProvider.notifier)
                                .remove(movie.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      },
    );
  }
}
