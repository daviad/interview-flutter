/// =============================================================================
/// HomeScreen widget 测试（对标 Android 版 FakeHomeApi 测试思路）
/// =============================================================================
///
/// 核心手法：override homeApiProvider 换假实现 —— 与生产代码同一套 DI 机制
/// （Riverpod override = Hilt 测试模块 / Koin test override）。
/// 测试全程不发真实网络请求、不需要 API key。
///
/// 🍎 UIKit 类比：XCTest 里注入 FakeHomeService，断言 ViewController
///    状态切换后视图出现/消失。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviely_core_ui/moviely_core_ui.dart';
import 'package:moviely_feature_home/moviely_feature_home.dart';
import 'package:moviely_feature_home/src/data/home_api.dart';
import 'package:moviely_feature_home/src/data/home_dtos.dart';
import 'package:moviely_feature_home/src/data/providers.dart';

/// 假 HomeApi：直接返回内存数据（可选首次失败，用于验证错误/重试）。
class FakeHomeApi implements HomeApi {
  FakeHomeApi({this.failFirstLoad = false});

  /// true = 首次加载抛异常（模拟断网），之后恢复正常（模拟重试成功）
  final bool failFirstLoad;
  int _callCount = 0;

  static const _popular = MovieResponseDto(
    page: 1,
    results: [
      MovieDto(
        id: 1,
        title: '假热门电影 A',
        overview: 'overview-a',
        posterPath: null, // null 海报走占位图标分支，不触发图片加载
        backdropPath: null,
        voteAverage: 8.4,
        releaseDate: '2024-01-01',
        genreIds: [28],
      ),
    ],
  );

  static const _nowPlaying = MovieResponseDto(
    page: 1,
    results: [
      MovieDto(
        id: 2,
        title: '假上映电影 B',
        overview: 'overview-b',
        posterPath: null,
        backdropPath: null,
        voteAverage: 7.0,
        releaseDate: '2024-02-02',
        genreIds: [],
      ),
    ],
  );

  @override
  Future<MovieResponseDto> getPopularMovies({int page = 1}) async {
    _callCount += 1;
    if (failFirstLoad && _callCount == 1) {
      throw Exception('模拟断网');
    }
    return _popular;
  }

  @override
  Future<MovieResponseDto> getNowPlayingMovies({int page = 1}) async {
    _callCount += 1;
    if (failFirstLoad && _callCount == 1) {
      throw Exception('模拟断网');
    }
    return _nowPlaying;
  }
}

/// 组装测试宿主：ProviderScope(override homeApiProvider) + MaterialApp。
Widget bootstrap(HomeApi api) {
  return ProviderScope(
    overrides: [homeApiProvider.overrideWithValue(api)],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('首次加载：Loading → 成功显示两个区块的电影标题', (tester) async {
    await tester.pumpWidget(bootstrap(FakeHomeApi()));

    // 首帧：全屏 Loading
    expect(find.byType(LoadingView), findsOneWidget);

    // 等假请求完成并重建（不用 pumpAndSettle：转圈动画会让它超时）
    await tester.pump(const Duration(milliseconds: 200));

    // 区块标题 + 电影数据均出现
    expect(find.text('热门电影'), findsOneWidget);
    expect(find.text('正在上映'), findsOneWidget);
    expect(find.text('假热门电影 A'), findsOneWidget);
    expect(find.text('假上映电影 B'), findsOneWidget);
    expect(find.byType(LoadingView), findsNothing);
  });

  testWidgets('加载失败：ErrorView + 重试按钮 → 点击后加载成功', (tester) async {
    await tester.pumpWidget(bootstrap(FakeHomeApi(failFirstLoad: true)));
    await tester.pump(const Duration(milliseconds: 200));

    // 首次失败：全屏错误态
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    // 点击「重试」：FakeHomeApi 第二次调用返回数据
    await tester.tap(find.text('重试'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('假热门电影 A'), findsOneWidget);
    expect(find.text('假上映电影 B'), findsOneWidget);
  });
}
