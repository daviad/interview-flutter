import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';
import 'package:moviely_core_ui/moviely_core_ui.dart';
import 'package:moviely_feature_favorite/moviely_feature_favorite.dart';

import 'detail_controller.dart';
import 'detail_state.dart';

/// =============================================================================
/// DetailScreen —— 详情页入口（对标 DetailScreen.kt）
/// =============================================================================
///
/// GoRoute path '/detail/:id' 的 builder 调用本 Screen，从 state.pathParams
/// 取出 movieId 传给 family provider `detailControllerProvider(movieId)`。
///
/// 布局（对标 Compose 版 DetailContent）：
///   - 顶部 SliverAppBar：背景大图 backdrop（可折叠）
///   - 海报 + 标题 + 年份/时长 + 类型 + 评分
///   - 剧情简介
///   - 演员表（横向滑动）
///   - 相似推荐（横向滑动，点击跳新详情）
class DetailScreen extends ConsumerWidget {
  const DetailScreen({required this.movieId, super.key});

  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(detailControllerProvider(movieId));

    return Scaffold(
      body: switch (state) {
        DetailLoading() => const LoadingView(),
        DetailError(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(detailControllerProvider(movieId).notifier).retry(),
          ),
        DetailSuccess(:final detail) => _DetailContent(detail: detail),
      },
    );
  }
}

/// =============================================================================
/// _DetailContent —— 详情页主体（CustomScrollView + Slivers）
/// =============================================================================
///
/// CustomScrollView + Sliver 工具箱（对标 Compose 的 LazyColumn + stickyHeader）：
///   - SliverAppBar：背景图 + 返回按钮（折叠时变 AppBar）
///   - SliverList：海报区 + 基本信息 + 简介 + 演员表 + 相似推荐
class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        _BackdropSliver(detail: detail),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _TitleRow(detail: detail),
              const SizedBox(height: 16),
              const SectionTitle('剧情简介'),
              const SizedBox(height: 8),
              Text(
                detail.overview.isEmpty ? '暂无简介' : detail.overview,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const SectionTitle('主演'),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        _CastSliver(detail: detail),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SectionTitle('相似推荐'),
            ]),
          ),
        ),
        _SimilarSliver(detail: detail),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

/// 顶部可折叠背景图 + 返回按钮 + 收藏按钮（SliverAppBar）
class _BackdropSliver extends ConsumerWidget {
  const _BackdropSliver({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: detail.backdropUrl.isEmpty
            ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
            : CachedNetworkImage(
                imageUrl: detail.backdropUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (_, _, _) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.movie_outlined, size: 48),
                ),
              ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      // 收藏按钮：调 favoriteRepository.toggle，本地跟踪 isFavorite 状态
      actions: [_FavoriteButton(detail: detail)],
    );
  }
}

/// 收藏切换按钮（对标 detail 页的 favorite FAB / icon）
///
/// 用 ConsumerStatefulWidget 本地持有 isFavorite：
///   - initState 异步查 repo.contains(id) 初始化
///   - 点击调 repo.toggle(movie) 拿新状态刷新图标
///   - SnackBar 提示「已收藏」/「已取消收藏」
class _FavoriteButton extends ConsumerStatefulWidget {
  const _FavoriteButton({required this.detail});

  final MovieDetail detail;

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  bool? _isFavorite;

  @override
  void initState() {
    super.initState();
    // 异步查初始状态（不阻塞 build，先 null 显示中性图标）
    Future<void>.microtask(() async {
      final repo = ref.read(favoriteRepositoryProvider);
      final v = await repo.contains(widget.detail.id);
      if (mounted) setState(() => _isFavorite = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fav = _isFavorite;
    final icon = fav == null
        ? Icons.bookmark_border
        : (fav ? Icons.bookmark : Icons.bookmark_border);
    return IconButton(
      icon: Icon(icon),
      tooltip: '收藏',
      onPressed: _toggle,
    );
  }

  Future<void> _toggle() async {
    final repo = ref.read(favoriteRepositoryProvider);
    // 复用详情字段构造 Movie（toggle 需要 Movie）
    final movie = widget.detail.toMovie();
    final nowFav = await repo.toggle(movie);
    if (!mounted) return;
    setState(() => _isFavorite = nowFav);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(nowFav ? '已加入收藏' : '已取消收藏')),
      );
  }
}

/// 标题 + 评分 + 年份/时长 + 类型标签
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 海报（小，120x180）
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 120,
            height: 180,
            child: detail.posterUrl.isEmpty
                ? Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.movie_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: detail.posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.title,
                style: theme.textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(detail.formattedVote, style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${detail.releaseDate} · ${detail.formattedRuntime}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: detail.genres
                    .map((g) => Chip(
                          label: Text(g, style: theme.textTheme.labelSmall),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 演员表（横向滑动）
class _CastSliver extends StatelessWidget {
  const _CastSliver({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.cast.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: EmptyState(message: '暂无演员信息'),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: detail.cast.length,
          itemBuilder: (context, index) {
            final c = detail.cast[index];
            return Container(
              width: 96,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: c.profileUrl.isEmpty
                          ? CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(Icons.person),
                            )
                          : CachedNetworkImage(
                              imageUrl: c.profileUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                              errorWidget: (_, _, _) => CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Icon(Icons.person),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    c.character,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 相似推荐（横向滑动，点击跳新详情）
class _SimilarSliver extends StatelessWidget {
  const _SimilarSliver({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.similarMovies.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: EmptyState(message: '暂无相似推荐'),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 232,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: detail.similarMovies.length,
          itemBuilder: (context, index) {
            final movie = detail.similarMovies[index];
            return Container(
              width: 128,
              margin: const EdgeInsets.only(right: 12),
              child: MovieCard(
                movie: movie,
                onTap: () => context.push(DetailRoute(movie.id).path),
              ),
            );
          },
        ),
      ),
    );
  }
}
