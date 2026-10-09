# 路由强类型化改造计划

## Context

当前工程所有跨模块导航都是字符串路径：
- `AppRoutes` 是抽象 final class，集中放路径常量（`/`、`/search`、`/favorite`、`/test`、`/detail/:id`）和拼接器 `detailPath(int) → '/detail/$id'`
- 4 处调用点统一写成 `context.push(AppRoutes.detailPath(movie.id))`

痛点：拼路径易出错、参数类型不强、调错运行时才崩。本次把"调用方输入"从字符串换成 sealed class，编译期检查参数类型；GoRouter 配置不动（仍按 path 字符串匹配），FeatureModule 协议不动，shell_router / main_shell 不动。改动范围最小、最稳，符合"不为不存在的场景提前抽象"铁律。

回调返回值（`push<T>` + `pop(value)`）暂不引入——当前无业务需求，等真有"详情页返回收藏变更通知列表刷新"等需求再扩。

## 设计

### 新增 sealed class `AppRoute`

位置：`packages/core/core_launch/lib/src/app_route.dart`

```dart
/// 强类型路由基类：编译期约束参数，序列化成 GoRouter 仍需的字符串路径。
///
/// 心智模型：sealed class 表达"本工程所有合法路由"，switch 穷尽匹配防漏；
/// path getter 把强类型对象转回 GoRouter 仍要的字符串路径
/// （GoRouter 7 仍是 path-based，本类只约束"调用方输入"那一侧）。
///
/// 🍎 UIKit 类比：自定义 Router 协议 + enum Route 表达目的地，
///    编译期检查 associated value 类型，运行时序列化成 URL。
/// 🍎 SwiftUI 类比：NavigationStack 的 path: [Route]，Route 是
///    enum with associated value，destination(for: Route.self) 穷尽匹配。
sealed class AppRoute {
  const AppRoute();

  /// 序列化成 GoRouter 路径字符串（仍由 GoRouter 按 path 匹配 GoRoute）
  String get path;
}

class HomeRoute extends AppRoute {
  const HomeRoute();
  @override
  String get path => AppRoutes.home;  // 复用常量，避免字符串重复
}

class SearchRoute extends AppRoute {
  const SearchRoute();
  @override
  String get path => AppRoutes.search;
}

class FavoriteRoute extends AppRoute {
  const FavoriteRoute();
  @override
  String get path => AppRoutes.favorite;
}

class TestRoute extends AppRoute {
  const TestRoute();
  @override
  String get path => AppRoutes.test;
}

/// 详情页压栈路由（带 id 参数，编译期约束类型）
class DetailRoute extends AppRoute {
  final int id;
  const DetailRoute(this.id);

  @override
  String get path => AppRoutes.detailPath(id);  // 复用拼接器
}
```

关键点：
- 子类**复用 `AppRoutes` 字符串常量**做 `path`，避免字符串字面量散布两处
- `DetailRoute(movie.id)` 不能 const（id 运行时），调用处省略 const
- `AppRoutes`（复数）字符串常量保留——GoRouter 注册 / `tabPaths` / `initialLocation` / `shell_router` 的 `route.path` 匹配都还在用它

### Barrel 导出

`packages/core/core_launch/lib/moviely_core_launch.dart` 第 7-9 行后追加：

```dart
export 'src/app_route.dart';
```

所有 feature 已经 `import 'package:moviely_core_launch/moviely_core_launch.dart';`，零新增 import 即可拿到 `DetailRoute` 等类型。

### 调用点替换（4 处，机械替换）

| 文件 | 行 | 原 | 新 |
|---|---|---|---|
| `packages/features/feature_home/lib/src/presentation/home_screen.dart` | L125 | `context.push(AppRoutes.detailPath(movie.id));` | `context.push(DetailRoute(movie.id).path);` |
| `packages/features/feature_favorite/lib/src/presentation/favorite_screen.dart` | L49-50 | `context.push(AppRoutes.detailPath(movie.id))` | `context.push(DetailRoute(movie.id).path)` |
| `packages/features/feature_search/lib/src/presentation/search_screen.dart` | L108 | `context.push(AppRoutes.detailPath(movie.id))` | `context.push(DetailRoute(movie.id).path)` |
| `packages/features/feature_detail/lib/src/presentation/detail_screen.dart` | L390 | `context.push(AppRoutes.detailPath(movie.id))` | `context.push(DetailRoute(movie.id).path)` |

4 处调用点的注释（如有"不 import 详情页"之类）保留不动，仍准确。

## 不动的文件（明确列出避免误改）

- `packages/core/core_launch/lib/src/app_routes.dart` —— 字符串常量保留，GoRouter 注册仍需
- `packages/core/core_launch/lib/src/feature_module.dart` —— 协议 `routes: List<RouteBase>`、`startRoute: String` 不变
- `app/lib/src/router/shell_router.dart` —— `AppRoutes.tabPaths.contains(route.path)` 等仍按字符串匹配
- `app/lib/src/router/main_shell.dart` —— `_tabs` 顺序与 `tabPaths` 一一对应
- `packages/app_launch/lib/src/launch_bootstrap.dart` —— 装配清单不变
- 各 feature 的 `XxxFeatureModule` —— `GoRoute(path: AppRoutes.xxx, ...)` 不变

## 文件同步铁律

按 `.trae/rules/project-essentials.md` 与 `AGENTS.md` 的"文件同步"约束，需在两处引导文件补一句：

- `.trae/rules/project-essentials.md` 第 1 节"架构"里 `core_launch` 那段：
  原文 `core_launch 定义 FeatureModule 协议、AppRoutes 路径契约（含 tab 路径...）、featureModulesProvider（默认空列表）。`
  → 末尾追加 `另有 AppRoute sealed class（HomeRoute/SearchRoute/FavoriteRoute/TestRoute/DetailRoute(id)）作为强类型路由入口，调用方传 sealed 子类后再 .path 序列化给 GoRouter。`

- `AGENTS.md` 第 1 节架构图 `core_launch` 那段类似追加同一行说明。

## 验证

1. **静态检查**：工作区根 `flutter analyze` → 必须 `No issues found!`
2. **widget 测试**：分别在 `feature_home`、`feature_favorite`、`feature_search`、`feature_detail` 包目录跑 `flutter test`，确认现有测试不破坏（如有 mock 路由的测试断言 path 字符串，应仍通过——path 字符串没变）
3. **手动冒烟**（可选）：`flutter run -d windows --dart-define=TMDB_API_KEY=<key>`，依次点 home/favorite/search/detail 的电影项进入详情页，确认导航行为一致

## 风险与回退

- 风险极低：sealed class 是新增类型，不改 GoRouter 行为，不改 path 字符串
- 唯一编译期约束：所有 `DetailRoute.id` 必须是 `int`——这正是要的类型安全
- 回退：删 `app_route.dart` + 撤 barrel export + 4 处调用点改回 `AppRoutes.detailPath(...)` 即可
