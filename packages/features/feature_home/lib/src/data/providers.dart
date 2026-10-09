import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviely_core_network/moviely_core_network.dart';

import 'home_api.dart';
import 'home_api_client.dart';

/// =============================================================================
/// homeApiProvider —— HomeApi 的 DI 绑定点
/// =============================================================================
///
/// 对标 Android 版 HomeModule 的 @Binds abstract fun bindHomeApi(impl: HomeApiClient): HomeApi
///
/// 【可插拔的关键】
///   页面/Controller 只依赖抽象 HomeApi（通过本 Provider 取）。
///   生产环境绑定 HomeApiClient；单元测试里一行 override 换成假实现：
///     homeApiProvider.overrideWithValue(FakeHomeApi())
///   等价 Hilt/Koin 测试模块替换绑定。
///
/// 🍎 UIKit 类比：DI 容器 register(HomeServiceProtocol.self) { HomeService() }，
///    测试时 register(FakeHomeService())。
final Provider<HomeApi> homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApiClient(ref.watch(tmdbClientProvider));
});
