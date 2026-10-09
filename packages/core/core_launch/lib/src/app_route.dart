/// =============================================================================
/// AppRoute —— 强类型路由基类 + 路由注册表
/// =============================================================================
///
/// 【职责】
///   ① sealed class 表达「本工程所有合法路由」，编译期约束参数类型；
///      每个子类自带路径字符串（path getter），不再依赖外部常量。
///   ② 静态 [tabs] 注册表：声明哪些路由是底部 tab 及其排列顺序，
///      由壳层 `shell_router.dart` 据此把各 feature 贡献的 GoRoute
///      分到 `StatefulShellRoute.indexedStack` 的对应 branch。
///
/// 【为什么把路径常量收进子类？】
///   旧设计有 `AppRoutes`（字符串常量集）+ `AppRoute`（sealed 子类）两份，
///   子类的 path 还要 `=> AppRoutes.xxx` 间接引用。路径字符串是路由类型
///   固有的属性，理应跟类型走；tab 注册表是壳级关注点，放 sealed class
///   上做静态常量最自然。最终 `AppRoutes` 删除，只剩 `AppRoute`。
///
/// 【用法】
///   ```dart
///   // 强类型跳转：DetailRoute(id) 编译期约束 id 为 int
///   context.push(DetailRoute(movie.id).path);
///
///   // tab 注册表（壳用，feature 不应直接依赖 tab 顺序）
///   final tabPaths = AppRoute.tabs.map((r) => r.path).toList();
///   ```
///
/// 🍎 UIKit 类比：自定义 Router 协议 + enum Route 表达目的地，
///    associated value 类型编译期检查，运行时序列化成 URL；
///    `AppRoute.tabs` 等价于 Router 里维护的「tab 项顺序表」。
/// 🍎 SwiftUI 类比：NavigationStack 的 `path: [Route]`，Route 是
///    `enum with associated value`；`tabs` 等价于主 TabView 的 `TabItem` 数组。
sealed class AppRoute {
  const AppRoute();

  /// 序列化成 GoRouter 路径字符串（GoRouter 仍按 path 匹配 GoRoute）。
  String get path;

  /// 底部 tab 路由注册表（顺序 = MainShell._tabs 顺序）。
  ///
  /// 壳层 `shell_router.dart` 遍历 feature modules 的 routes 时，
  /// 用本列表的 path 判定哪些是 tab 路由、接到哪个 branch。
  /// 新增/调整 tab 必须同时改 `main_shell.dart` 的 `_tabs`（icon/label）。
  ///
  /// 注意：detail 等压栈路由不在此列，由壳自动挂到根层。
  static const List<AppRoute> tabs = <AppRoute>[
    HomeRoute(),
    SearchRoute(),
    FavoriteRoute(),
    TestRoute(),
  ];
}

/// 首页 tab 路由（无参，对应底部第 1 个 tab）。
class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  String get path => '/';
}

/// 搜索 tab 路由（无参，对应底部第 2 个 tab）。
class SearchRoute extends AppRoute {
  const SearchRoute();

  @override
  String get path => '/search';
}

/// 收藏 tab 路由（无参，对应底部第 3 个 tab）。
class FavoriteRoute extends AppRoute {
  const FavoriteRoute();

  @override
  String get path => '/favorite';
}

/// Test tab 路由（无参，对应底部第 4 个 tab）。
class TestRoute extends AppRoute {
  const TestRoute();

  @override
  String get path => '/test';
}

/// 详情页压栈路由（带 id 参数，编译期约束类型）。
///
/// 不在 [tabs] 中：进入后由壳层挂到根路由（压栈，隐藏底栏）。
///
/// 【注册 vs 导航的两个字符串】
///   - [pathTemplate] `/detail/:id`：给 GoRouter 注册 GoRoute 用，声明参数占位符；
///   - [path] `/detail/$id`：导航时 `context.push(DetailRoute(123).path)` 拼接具体 id。
///   GoRouter 用模板匹配路径，从 pathParameters 取出 id，builder 里
///   `int.parse(state.pathParameters['id']!)` 还原成 int。
class DetailRoute extends AppRoute {
  final int id;

  const DetailRoute(this.id);

  /// GoRoute 注册用的路径模板（含 `:id` 占位符）。
  static const String pathTemplate = '/detail/:id';

  @override
  String get path => '/detail/$id';
}
