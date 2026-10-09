import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviely_core_network/moviely_core_network.dart';

import 'detail_api.dart';
import 'detail_api_client.dart';

/// =============================================================================
/// detailApiProvider —— DetailApi 的 DI 绑定点
/// =============================================================================
///
/// 对标 Android 版 DetailModule 的 @Binds abstract fun bindDetailApi(impl): DetailApi
final Provider<DetailApi> detailApiProvider = Provider<DetailApi>((ref) {
  return DetailApiClient(ref.watch(tmdbClientProvider));
});
