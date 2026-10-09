import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feature_module.dart';

/// =============================================================================
/// featureModulesProvider —— 已装配模块清单（多绑定集合的 Riverpod 版）
/// =============================================================================
///
/// 对标 Android app-launch/LaunchModule.kt 里的：
///
///   `@Provides @ElementsIntoSet @AllModuleLifecycle`
///   `fun bindModuleLifecycleSet(): Set<ModuleLifecycle> = emptySet()`
///
/// 【机制对照】
///   Android/Hilt：协议层定义接口，feature 用 @Binds @IntoSet 贡献实现，
///                 Hilt 自动把所有贡献收集成 `Set<T>` 注入；
///                 没有任何 feature 接入时，@ElementsIntoSet emptySet()
///                 声明「空集合默认」，保证壳独立可编译可运行。
///
///   Flutter/Riverpod：协议层声明本 Provider，默认返回空列表 []。
///                 聚合器（app_launch 包）用 overrideWithValue([...])
///                 把各 feature 的 FeatureModule 实例「贡献」进来；
///                 测试里可以继续 override 成假模块。
///
/// 【为什么默认空列表而不是抛异常？】
///   与 Android 空 Set 默认同理：壳工程在「零 feature 接入」时也要能启动，
///   GoRouter 聚合到空列表会渲染"无模块接入"占位页（见 app/shell_router.dart）。
///   feature 接入是「增量 override」而不是「修改壳代码」。
///
/// 🍎 UIKit 类比：ServiceLocator 里 resolveMany(FeatureModule.self)
///    默认返回空数组，宿主 App 装配时注册具体模块。
/// 🍎 SwiftUI 类比：EnvironmentKey 默认值为 []，App 层注入真实模块列表。
final Provider<List<FeatureModule>> featureModulesProvider =
    Provider<List<FeatureModule>>((ref) {
  // 空列表默认 = Hilt 的 @ElementsIntoSet emptySet()。
  // 真实模块由 app_launch 包通过 ProviderScope(overrides:) 覆盖。
  return const <FeatureModule>[];
});
