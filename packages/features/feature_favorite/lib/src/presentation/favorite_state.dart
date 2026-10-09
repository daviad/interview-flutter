import 'package:moviely_core_domain/moviely_core_domain.dart';

/// =============================================================================
/// FavoriteState —— 收藏页 MVI 状态
/// =============================================================================
///
/// 三态 sealed：Loading/Error/Success。Success 携带收藏列表。
/// 删除/添加后 Controller 重新加载，UI 自动刷新（对标 Android Flow 自动刷新）。
sealed class FavoriteState {
  const FavoriteState();
}

class FavoriteLoading extends FavoriteState {
  const FavoriteLoading();
}

class FavoriteError extends FavoriteState {
  const FavoriteError(this.message);

  final String message;
}

class FavoriteSuccess extends FavoriteState {
  const FavoriteSuccess({required this.movies});

  final List<Movie> movies;
}
