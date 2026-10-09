import 'package:moviely_core_domain/moviely_core_domain.dart';

/// =============================================================================
/// SearchState —— 搜索页 MVI 状态（对标 SearchUiState.kt）
/// =============================================================================
///
/// 区分四态：未输入 / 加载中 / 有结果 / 无结果 / 失败。
/// 用 sealed class 三态承载 Loading/Success/Error，Success 内含
/// query/movies/hasSearched 区分「有结果」与「未搜索/空结果」。
sealed class SearchState {
  const SearchState();
}

/// 初始态（未搜索）：引导提示
class SearchInitial extends SearchState {
  const SearchInitial();
}

/// 加载中：显示转圈（query 保留供输入框显示）
class SearchLoading extends SearchState {
  const SearchLoading(this.query);

  final String query;
}

/// 失败：错误信息 + 重试
class SearchError extends SearchState {
  const SearchError(this.query, this.message);

  final String query;
  final String message;
}

/// 成功（含结果为空的情况，用 movies.isEmpty 区分）
class SearchSuccess extends SearchState {
  const SearchSuccess({
    required this.query,
    required this.movies,
    required this.hasSearched,
  });

  final String query;
  final List<Movie> movies;

  /// 是否已发起过搜索（true + movies 空显示「没找到」，false 显示初始引导）
  final bool hasSearched;
}
