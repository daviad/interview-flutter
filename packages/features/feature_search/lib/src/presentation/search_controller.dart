import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/providers.dart';
import 'search_state.dart';

part 'search_controller.g.dart';

/// =============================================================================
/// SearchController —— 搜索页 MVI 中枢（对标 SearchViewModel.kt）
/// =============================================================================
///
/// 【输入防抖（debounce 450ms）】
///   Learn 版用 Kotlin Flow.debounce(450ms)；Dart 用 Timer + _debounceTimer
///   手写：onQueryChanged 收到新输入时取消上一个 timer，450ms 后无新输入
///   才真正发请求。避免每输入一个字就请求一次（对标 Compose 的 debounce）。
///
///   🍎 UIKit 类比：UITextField 的EditingChanged 加 DispatchWorkItem
///   cancel() + asyncAfter(450ms) 实现；SwiftUI 用 .task(id:)。
@riverpod
class SearchController extends _$SearchController {
  Timer? _debounceTimer;

  @override
  SearchState build() {
    // 释放时取消未触发的防抖定时器，避免 controller dispose 后还回调
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SearchInitial();
  }

  /// 输入框文本变化（防抖 450ms 后触发搜索）
  ///
  /// 空查询直接回到初始态，不发请求。
  void onQueryChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchInitial();
      return;
    }

    // 防抖：450ms 内若再输入则取消，等用户停顿再发请求
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      _search(trimmed);
    });
  }

  /// 键盘「搜索」按钮立即触发（跳过防抖）
  void onSubmit(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _search(trimmed);
  }

  /// 核心业务：发起搜索请求（对标 SearchViewModel.search()）
  Future<void> _search(String query) async {
    final searchApi = ref.read(searchApiProvider);
    state = SearchLoading(query);
    try {
      final resp = await searchApi.searchMovies(query);
      state = SearchSuccess(
        query: query,
        movies: resp.results.map((dto) => dto.toMovie()).toList(),
        hasSearched: true,
      );
    } on DioException catch (_) {
      state = SearchError(query, '网络请求失败，请检查网络后重试');
    } catch (_) {
      state = SearchError(query, '数据解析失败，请稍后重试');
    }
  }
}
