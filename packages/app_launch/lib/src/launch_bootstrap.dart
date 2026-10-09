// Riverpod 3：Override 类型从 misc 库公开导出（主 barrel 不再导出内部类型）
import 'package:flutter_riverpod/misc.dart';
import 'package:moviely_core_launch/moviely_core_launch.dart';
import 'package:moviely_feature_detail/moviely_feature_detail.dart';
import 'package:moviely_feature_favorite/moviely_feature_favorite.dart';
import 'package:moviely_feature_home/moviely_feature_home.dart';
import 'package:moviely_feature_search/moviely_feature_search.dart';
import 'package:moviely_feature_test/moviely_feature_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =============================================================================
/// bootstrapOverrides —— 模块装配清单（对标 AppLaunchAggregator）
/// =============================================================================
///
/// 【可插拔，就是改这里】
///   Android 版（Hilt）：
///     `@Provides fun featureModules(home): @IntoSet Set<FeatureModule>`
///   Flutter 版（Riverpod override）：
///     `featureModulesProvider.overrideWithValue([HomeFeatureModule(), ...])`
///
/// 壳工程 main() 把本列表展开进 ProviderContainer.overrides，
/// 之后壳遍历 featureModulesProvider 逐个调 onCreate()，
/// 再把各模块的 routes 聚合进 GoRouter —— 壳全程不认识任何具体 feature。
///
/// 【当前接入的模块】
///   - HomeFeatureModule     → '/'（底部 tab 1：首页）
///   - SearchFeatureModule   → '/search'（底部 tab 2：搜索）
///   - FavoriteFeatureModule → '/favorite'（底部 tab 3：收藏）
///   - DetailFeatureModule   → '/detail/:id'（压栈路由，不在 tab 内）
///   - TestFeatureModule     → '/test'（底部 tab 4：练习）
///
/// 拔掉任意一个 feature，对应 tab/路由显示占位页，App 仍可编译运行。
///
/// 【为什么这里也注入 favoriteRepository？】
///   铁律 1：app 壳禁止 import 任何 feature_*。但 favoriteRepositoryProvider
///   定义在 feature_favorite 包，SharedPreferences 又是异步初始化的。
///   折中：app_launch 作为「唯一能 import feature 的聚合器」，承担
///   SharedPreferences 初始化 + favoriteRepository 注入，壳 main 只调
///   [buildBootstrapOverrides] 取现成的 overrides 列表（壳零 feature import）。
final List<Override> bootstrapOverrides = [
  featureModulesProvider.overrideWithValue(const <FeatureModule>[
    HomeFeatureModule(),
    SearchFeatureModule(),
    FavoriteFeatureModule(),
    DetailFeatureModule(),
    TestFeatureModule(),
  ]),
];

/// 异步初始化的 override（SharedPreferences → favoriteRepositoryProvider）。
///
/// 壳 main() 在 `await SharedPreferences.getInstance()` 之前不能构造
/// FavoriteRepository，所以这部分单独异步函数产出，与 [bootstrapOverrides]
/// 合并注入 ProviderContainer.overrides。
///
/// 返回 `List<Override>` 而非单值，方便未来加更多需要异步初始化的 Provider。
Future<List<Override>> buildAsyncBootstrapOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  return [
    favoriteRepositoryProvider.overrideWithValue(FavoriteRepository(prefs)),
  ];
}
