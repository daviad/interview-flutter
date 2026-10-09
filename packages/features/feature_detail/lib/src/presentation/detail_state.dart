import 'package:moviely_core_domain/moviely_core_domain.dart';

/// =============================================================================
/// DetailState —— 详情页 MVI 状态（对标 DetailUiState.kt）
/// =============================================================================
///
/// 三态 sealed class（Loading/Error/Success），UI switch 穷尽匹配。
/// 与 HomeState 结构一致，只是 Success 携带 MovieDetail 而非 `List<Movie>`。
sealed class DetailState {
  const DetailState();
}

/// 首次加载：全屏转圈
class DetailLoading extends DetailState {
  const DetailLoading();
}

/// 加载失败：全屏错误 + 重试
class DetailError extends DetailState {
  const DetailError(this.message);

  final String message;
}

/// 加载成功：渲染详情
class DetailSuccess extends DetailState {
  const DetailSuccess({required this.detail});

  final MovieDetail detail;
}
