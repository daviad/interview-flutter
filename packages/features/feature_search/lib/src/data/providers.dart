import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviely_core_network/moviely_core_network.dart';

import 'search_api.dart';
import 'search_api_client.dart';

/// =============================================================================
/// searchApiProvider —— SearchApi 的 DI 绑定点
/// =============================================================================
final Provider<SearchApi> searchApiProvider = Provider<SearchApi>((ref) {
  return SearchApiClient(ref.watch(tmdbClientProvider));
});
