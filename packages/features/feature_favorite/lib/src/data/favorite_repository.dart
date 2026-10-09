import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviely_core_domain/moviely_core_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =============================================================================
/// FavoriteRepository —— 收藏本地持久化（对标 Android 版 data-db 的 FavoriteDao）
/// =============================================================================
///
/// 【为什么用 shared_preferences 而不是 Room/drift/hive？】
///   Learn Android 版用 Room（FavoriteDao + Flow）。Flutter 等价是 drift/sqflite，
///   但收藏数据量小（几十到几百条），shared_preferences 存 JSON 列表已足够，
///   且零额外依赖管理成本。学习场景下选最简方案。
///
///   🍎 UIKit 类比：UserDefaults 存数组（小数据量场景同理）。
///
/// 【存储格式】
///   key = 'favorites'，value = JSON 字符串（List<Map>）。
///   每次 add/remove 重写整个列表（小数据量可接受，简单不易错）。
///
/// 【跨模块共享】
///   favoriteRepositoryProvider 在本包 barrel 导出，feature_detail import 它
///   做收藏切换；feature_favorite 自己的页面也用它读列表。Riverpod 单例
///   保证两个 feature 拿到同一个 Repository 实例，state 联动。
class FavoriteRepository {
  FavoriteRepository(this._prefs);

  static const _key = 'favorites';

  final SharedPreferences _prefs;

  /// 读全部收藏（按 addedAt 倒序：最新收藏在前）
  Future<List<FavoriteEntry>> getAll() async {
    final raw = _prefs.getStringList(_key) ?? const [];
    try {
      return raw
          .map((s) => FavoriteEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    } catch (e) {
      debugPrint('[FavoriteRepository] 读取失败: $e');
      return const [];
    }
  }

  /// 是否已收藏（同步，供 UI 快速判断图标）
  Future<bool> contains(int movieId) async {
    return (await getAll()).any((e) => e.movieId == movieId);
  }

  /// 加入收藏（已存在则跳过）
  Future<void> add(Movie movie) async {
    final list = await getAll();
    if (list.any((e) => e.movieId == movie.id)) return;
    list.add(FavoriteEntry.fromMovie(movie, addedAt: DateTime.now()));
    await _write(list);
  }

  /// 移除收藏
  Future<void> remove(int movieId) async {
    final list = await getAll();
    list.removeWhere((e) => e.movieId == movieId);
    await _write(list);
  }

  /// 切换收藏状态（对标 detail 页的 favorite toggle 按钮）
  Future<bool> toggle(Movie movie) async {
    final list = await getAll();
    final existed = list.any((e) => e.movieId == movie.id);
    if (existed) {
      list.removeWhere((e) => e.movieId == movie.id);
    } else {
      list.add(FavoriteEntry.fromMovie(movie, addedAt: DateTime.now()));
    }
    await _write(list);
    return !existed; // 返回新状态（true=已收藏）
  }

  Future<void> _write(List<FavoriteEntry> list) async {
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_key, raw);
  }
}

/// 收藏条目（Movie + 收藏时间，用于排序）
class FavoriteEntry {
  const FavoriteEntry({
    required this.movieId,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
    required this.addedAt,
  });

  final int movieId;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;
  final DateTime addedAt;

  factory FavoriteEntry.fromMovie(Movie movie, {required DateTime addedAt}) {
    return FavoriteEntry(
      movieId: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
      genreIds: movie.genreIds,
      addedAt: addedAt,
    );
  }

  /// 转回 Domain Movie（UI 复用 MovieCard/MovieListTile）
  Movie toMovie() => Movie(
        id: movieId,
        title: title,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
        genreIds: genreIds,
      );

  Map<String, dynamic> toJson() => {
        'movie_id': movieId,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'vote_average': voteAverage,
        'release_date': releaseDate,
        'genre_ids': genreIds,
        'added_at': addedAt.toIso8601String(),
      };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    return FavoriteEntry(
      movieId: (json['movie_id'] as num).toInt(),
      title: json['title'] as String,
      overview: json['overview'] as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num).toDouble(),
      releaseDate: json['release_date'] as String,
      genreIds: (json['genre_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
}

/// =============================================================================
/// favoriteRepositoryProvider —— 跨模块共享的收藏 Repository DI 入口
/// =============================================================================
///
/// **必须在壳 main() 里 await SharedPreferences.getInstance() 后 override 注入**，
/// 因为 SharedPreferences 是异步初始化的，core_network 风格的「契约抛错」
/// 在这里也适用：默认抛 UnimplementedError，壳注入实例后可用。
///
/// feature_detail 和 feature_favorite 都通过 ref.watch(favoriteRepositoryProvider)
/// 取同一个 Repository 实例（Riverpod 单例），state 联动。
final Provider<FavoriteRepository> favoriteRepositoryProvider =
    Provider<FavoriteRepository>((ref) {
  throw UnimplementedError(
    'favoriteRepositoryProvider 未装配：请在 ProviderScope(overrides:) 中注入 '
    'favoriteRepositoryProvider.overrideWithValue(FavoriteRepository(prefs))',
  );
});
