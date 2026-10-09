import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';
import 'package:moviely_core_ui/moviely_core_ui.dart';

import 'search_controller.dart';
import 'search_state.dart';

/// =============================================================================
/// SearchScreen —— 搜索页入口（对标 SearchScreen.kt）
/// =============================================================================
///
/// 布局：AppBar 内嵌搜索框 + 内容区四态（初始/加载/错误/结果）。
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '搜索电影',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.clear),
          ),
          onChanged: ref.read(searchControllerProvider.notifier).onQueryChanged,
          onSubmitted: ref.read(searchControllerProvider.notifier).onSubmit,
        ),
      ),
      body: switch (state) {
        SearchInitial() => const EmptyState(message: '输入电影名开始搜索'),
        SearchLoading(:final query) => _SearchLoadingView(query: query),
        SearchError(:final message) => ErrorView(
            message: message,
            onRetry: () => ref
                .read(searchControllerProvider.notifier)
                .onSubmit(state.query),
          ),
        SearchSuccess(:final movies, :final hasSearched) =>
          hasSearched && movies.isEmpty
              ? const EmptyState(message: '没有找到相关电影')
              : _SearchResults(movies: movies),
      },
    );
  }
}

/// 加载态：转圈 + 显示当前查询
class _SearchLoadingView extends StatelessWidget {
  const _SearchLoadingView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text('正在搜索「$query」...'),
        ],
      ),
    );
  }
}

/// 搜索结果列表（纵向 ListView，点击跳详情）
class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MovieListTile(
            movie: movie,
            onTap: () => context.push(DetailRoute(movie.id).path),
          ),
        );
      },
    );
  }
}
