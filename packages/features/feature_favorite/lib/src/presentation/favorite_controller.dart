import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/favorite_repository.dart';
import 'favorite_state.dart';

part 'favorite_controller.g.dart';

/// =============================================================================
/// FavoriteController —— 收藏页 MVI 中枢（对标 FavoriteViewModel.kt）
/// =============================================================================
///
/// build() 加载收藏列表；remove 调用后重新加载刷新 UI。
/// 跨模块联动：feature_detail 调 favoriteRepository.toggle 后切回本 tab，
/// Riverpod 不会自动重建 FavoriteController（因为它订阅的是 repository
/// 而不是收藏变化的流），所以本 Controller 提供 refresh() 手动刷新，
/// 推荐用 ref.listen 在 tab 切回时触发刷新（详见 FavoriteScreen）。
@riverpod
class FavoriteController extends _$FavoriteController {
  @override
  FavoriteState build() {
    Future<void>.microtask(() => _load());
    return const FavoriteLoading();
  }

  /// 重新加载收藏列表（手动刷新 / 删除后刷新）
  Future<void> refresh() => _load();

  /// 移除收藏（对标 FavoriteIntent.Remove）
  Future<void> remove(int movieId) async {
    final repo = ref.read(favoriteRepositoryProvider);
    await repo.remove(movieId);
    await _load();
  }

  Future<void> _load() async {
    final repo = ref.read(favoriteRepositoryProvider);
    try {
      final entries = await repo.getAll();
      state = FavoriteSuccess(
        movies: entries.map((e) => e.toMovie()).toList(),
      );
    } catch (_) {
      state = const FavoriteError('读取收藏失败');
    }
  }
}
