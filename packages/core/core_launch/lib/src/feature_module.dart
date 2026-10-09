import 'package:go_router/go_router.dart';

import 'app_route.dart';

/// =============================================================================
/// FeatureModule —— feature 模块接入壳工程的「装配协议」
/// =============================================================================
///
/// 对标 Android common-launch 模块的两个接口：
///   ModuleLifecycle（App.onCreate 时分发初始化回调）
///   ModuleNavigator（NavGraphBuilder.registerRoutes() 贡献路由）
///
/// Flutter 版把两个协议合并成一个抽象类（FeatureModule 足够简单；
/// 复杂模块可以在实现类里拆分职责）。每个 feature 提供一个实现类
/// （如 feature_home 的 HomeFeatureModule），由聚合器（app_launch）
/// 汇总进 [featureModulesProvider]。
///
/// 【为什么壳和 feature 都依赖这个抽象？】
///   壳工程只 import core_launch，拿到的是 `List<FeatureModule>`，
///   完全不知道里面是 HomeFeatureModule 还是别的模块 —— 这就是
///   「壳工程永不 import feature」原则在 Flutter 下的落地方式。
///
/// 🍎 UIKit 类比：BeeHive 组件化框架的 BHModuleProtocol —— 每个业务模块
///    实现协议，AppDelegate 启动时遍历注册的模块统一分发生命周期；
///    路由部分对应「每个模块向中央 Router 注册自己的 path→Builder」。
/// 🍎 SwiftUI 类比：一个 Module 协议，App 启动时遍历 [Module] 调 boot()
///    并把各自的 navigationDestination 挂到 NavigationStack 上。
abstract interface class FeatureModule {
  /// 模块初始化：App 启动时（runApp 之前）由壳统一遍历调用。
  ///
  /// 对标 ModuleLifecycle.onCreate(context)：埋点/推送/数据库预热等
  /// feature 自己的初始化逻辑放这里，壳工程不感知具体内容。
  ///
  /// 异步方法：壳会 await 全部模块初始化完成后再 runApp
  /// （Android 版 onCreate 是同步的，Dart 用 Future 表达异步初始化更自然）。
  Future<void> onCreate() async {}

  /// 模块销毁回调（对标 ModuleLifecycle.onTerminate）。
  /// 真机进程被杀时几乎不触发，仅占位，不放关键回收逻辑。
  void onTerminate() {}

  /// 本模块贡献的路由表。
  ///
  /// 对标 ModuleNavigator.NavGraphBuilder.registerRoutes()：
  /// feature 自己声明 path → 页面 的映射，壳的 GoRouter 聚合所有模块的 routes。
  /// GoRoute 是 go_router 的路由项（= Compose Navigation 的 composable("home"){...}）。
  ///
  /// 🍎 UIKit 类比：[URLRouter registerPath:builder:] 注册一批 path。
  List<RouteBase> get routes;

  /// 本模块声明的起始路由（当前只有首页模块返回 [HomeRoute]）。
  /// 预留字段：未来多 tab/多入口模块可由壳协商启动目的地。
  /// 用 [AppRoute] 强类型表达，避免字符串拼写错误。
  AppRoute get startRoute;
}
