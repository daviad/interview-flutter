import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';

/// =============================================================================
/// MovieCard —— 海报卡片（横向滑动列表用，对标 Compose 版 MovieCard）
/// =============================================================================
///
/// 竖版海报（w500 图）+ 标题；点击由外层传入回调。
///
/// 图片加载用 cached_network_image：自带内存/磁盘缓存 + 占位/错误兜底，
/// 等价 Android 的 Coil（AsyncImage）。
///
/// 🍎 UIKit 类比：UIImageView + SDWebImage（sd_setImage(with:)）；
/// 🍎 SwiftUI 类比：AsyncImage(url:) 加缓存封装。
class MovieCard extends StatelessWidget {
  const MovieCard({required this.movie, required this.onTap, super.key});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 海报：宽 120、高 180（2:3 电影海报比例），ContentScale.Crop
              Expanded(
                child: _Poster(url: movie.posterUrl, iconSize: 32),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  movie.title,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 海报图片公共部件：CachedNetworkImage + 加载中/失败占位。
class _Poster extends StatelessWidget {
  const _Poster({required this.url, this.iconSize = 24});

  final String url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Icon(Icons.movie_outlined, size: iconSize);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) => Icon(Icons.broken_image_outlined, size: iconSize),
    );
  }
}
