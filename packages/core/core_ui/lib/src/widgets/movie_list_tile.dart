import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';

/// =============================================================================
/// MovieListTile —— 横排列表项（纵向列表用，对标 Compose 版 Card+Row 布局）
/// =============================================================================
///
/// 小海报（80x120）+ 标题/评分/上映日期。
class MovieListTile extends StatelessWidget {
  const MovieListTile({required this.movie, required this.onTap, super.key});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap, // InkWell 给水波点击效果（等价 Compose Card(onClick=)）
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 80,
                  height: 120,
                  child: _TilePoster(url: movie.posterUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '评分: ${movie.formattedVote}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      movie.releaseDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TilePoster extends StatelessWidget {
  const _TilePoster({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.movie_outlined),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: Colors.black12),
      errorWidget: (_, _, _) => const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
