# Moviely Flutter 模块间通信方案笔记

> 本文档整理模块化通信的完整讨论，覆盖 Flutter (Riverpod + GoRouter)、
> Android (Hilt + Kotlin)、Swift (Swinject + SwiftUI) 三平台的对照实现，
> 便于以后学习回顾。
>
> 上下文：当前工程是三段式可插拔组件化架构
> （`app/` 壳 → `app_launch/` 聚合器 → `core_*` + `features/*`），
> 状态管理用 Riverpod 3，路由用 GoRouter。
> 铁律：feature 之间禁止直接 import，所有跨模块通信必须走"抽象 + 装配"。

---

## 目录

- [一、Flutter 模块化通信方案](#一flutter-模块化通信方案)
  - [1.1 通信场景分类](#11-通信场景分类)
  - [1.2 七种主要方案](#12-七种主要方案)
  - [1.3 方案对比表](#13-方案对比表)
  - [1.4 针对本工程的建议](#14-针对本工程的建议)
  - [1.5 反模式提醒](#15-反模式提醒)
- [二、Android (Hilt) 与 Swift (Swinject) 三平台对照](#二android-hilt-与-swift-swinject-三平台对照)
  - [2.1 装配点的对照](#21-装配点的对照核心心智先对齐)
  - [2.2 Android (Hilt + Kotlin) 实现](#22-android-hilt--kotlin)
  - [2.3 Swift (Swinject + SwiftUI) 实现](#23-swift-swinject--swiftui)
  - [2.4 三平台总对比](#24-三平台总对比)
  - [2.5 关键对照洞察](#25-关键对照洞察)
  - [2.6 与本工程的映射](#26-回到本工程)
- [三、强类型路由 + 回调返回值三平台 demo](#三强类型路由--回调返回值三平台-demo)
  - [3.1 设计思路](#31-设计思路先对齐)
  - [3.2 Flutter (GoRouter) demo](#32-flutter-gorouter-demo)
  - [3.3 Android (Compose Navigation 2.8+) demo](#33-android-compose-navigation-28-demo)
  - [3.4 Swift (SwiftUI NavigationStack) demo](#34-swift-swiftui-navigationstack-ios-16-demo)
  - [3.5 三平台对照总结](#35-三平台对照总结)
  - [3.6 反模式](#36-反模式三平台通用)
- [四、心智模型总结](#四心智模型总结)

---

## 一、Flutter 模块化通信方案

### 1.1 通信场景分类

不同场景适合不同方案，不能一把梭。先识别属于哪类：

| 类型 | 场景 | 本工程已有例子 |
|---|---|---|
| A. 导航 | 跳到 B 的页面 / 拿返回值 | home → `/detail/:id` |
| B. 状态/数据共享 | A 读 B 持有的状态 | detail 读 favorite 的收藏状态 |
| C. 功能调用 | A 调 B 的业务能力 | detail 调"加收藏" |
| D. UI 复用 | A 嵌入 B 的 widget | home 嵌入 search 的搜索栏 |
| E. 事件通知 | B 发生事件，A 响应 | favorite 变更 → home 刷新徽标 |

> 判断方案的第一步是先识别属于哪类。
> 导航用方案 1，UI 复用用方案 6/7，事件通知用方案 4 或 Riverpod 原生机制。

### 1.2 七种主要方案

#### 方案 1：路由契约（路径通信）— 适合 A 类导航

`context.push('/detail/123')` / `context.push<bool>('/login')` 拿返回值。
本工程 `AppRoutes` 就是这个设计意图：A 只认字符串常量，不 import B。

- **优点**：完全解耦、可插拔（B 拔掉 → 占位页/降级）、与 Android Intent / iOS URL Scheme 同构
  （🍎 类比 `UIApplication.openURL` + Router host）
- **缺点**：只能传基本类型（path/query），不能传复杂对象；无编译期检查；
  不适合"取状态/调功能/复用 UI"

#### 方案 2：共享 Provider（Riverpod 跨模块）— 适合 B/C 类

把要共享的 Provider 定义在 feature 的 lib/ 暴露层（如 `favorite.dart`），
app_launch 用 override 把它注入另一个 feature 的**同名抽象 Provider**。

本工程已经在用：`feature_favorite` 暴露 `favoriteRepositoryProvider`，
`feature_detail` 定义同名抽象 Provider（指向 `FavoriteRepository` 接口），
app_launch 的 `bootstrapOverrides` 用实现去 override 抽象。

**关键技巧是依赖倒置**：
- `core_domain` / `core_launch` 定义抽象接口 `FavoriteRepository`
- feature 实现它
- feature_detail 只依赖抽象
- app_launch 在 override 里完成"接线"

- **优点**：Riverpod 原生、类型安全、可测试（Fake override）、编译期解耦、
  状态变化自动通知 watch 者
- **缺点**：只适合"状态/服务接口"，不适合复用 Widget；
  新增共享点要改装配层；跨模块用 watch 还是 read 要小心
  （watch 会触发重建，建议 build 里 `ref.read`，副作用用 `ref.listen`）

#### 方案 3：服务定位器（get_it + Injectable）— 不推荐

core 定义接口，feature 实现并注册到 `get_it`，A 用 `getIt<BService>()` 取。

- **优点**：解耦彻底、不依赖 Riverpod
- **缺点**：运行时解析（找不到才崩）、没编译期保证；在 Riverpod 工程里重复造轮子；
  测试替换不如 `provider.overrideWithValue` 直观
- 🍎 类比：像 UIKit 的 `UIApplication.shared.delegate` 拿到根对象再去取依赖，弱类型

> **在本工程里是反模式**——Riverpod 本身就是 DI 容器。

#### 方案 4：事件总线 / Stream 广播 — 适合 E 类，谨慎用

`StreamController<Event>.broadcast()` 或 EventBus，B 发 A 订阅。

- **优点**：完全解耦、天然一对多、适合"事件"而非"状态"
- **缺点**：数据流难追踪、易内存泄漏（订阅不 dispose）、新订阅者拿不到历史状态、
  容易变成大泥球
- 🍎 类比：`NotificationCenter.default` / Combine `Publisher`

> **在 Riverpod 项目里 80% 是反模式**——能用 `ref.listen` + 共享 Provider 解决的，
> 不要走总线。只有"跨多模块、无明确消费者、纯广播"才考虑。

#### 方案 5：依赖倒置 + 装配层注入 — 通用方案（本工程核心模式）

方案 2 的泛化版：core 定义抽象、feature 实现、app_launch override 接线。
可承载"功能调用""状态共享""UI 复用"所有场景。

- **优点**：编译期类型安全、符合 DIP、可测试、可插拔架构正解
- **缺点**：接线点单一（app_launch），新增共享点必须改装配层；
  抽象接口泛滥时啰嗦

#### 方案 6：core_ui 提取共享 UI 组件 — 适合 D 类"通用"组件

`MovieCard`、`Loading`、`ErrorView`、`Empty` 放 core_ui，所有 feature 都能用。

- **优点**：简单直接、无接线、符合 DRY
- **缺点**：只适合"通用"组件；feature 私有的 UI 不应提到 core；
  core_ui 容易变成大杂烩（要克制）
- 🍎 类比：把组件提到 core_ui 等于把它们做成可复用 UIView，
  所有人都 import；但 feature 私有的 screen 不应该这么提

#### 方案 7：Widget Provider（暴露 builder）— 适合 D 类"feature 私有 widget 跨模块复用"

如果 A 想嵌入 B 私有的 widget（不想提到 core_ui），
用依赖倒置的思路但暴露 Widget builder：

```dart
// core_launch 或 feature_search 暴露层定义抽象
@riverpod
Widget Function(BuildContext, SearchBarParams) searchBarBuilder(Ref ref)
    => throw UnimplementedError();

// feature_search 实现并注册到 app_launch override
// feature_home 使用：
final builder = ref.watch(searchBarBuilderProvider);
return builder(context, params);
```

- **优点**：feature 私有 widget 也能跨模块共享、类型安全、可测试
- **缺点**：复杂度上升（要定义抽象 Provider + 参数类型 + API 约定）；
  Widget 是不可变快照，状态管理还是要回 Riverpod
- 🍎 类比：把 B 的 UIViewController 用工厂方法暴露给 A 嵌入 child view controller，
  A 不直接 import B 的类

### 1.3 方案对比表

| 方案 | 适用场景 | 解耦度 | 类型安全 | 可测试 | 复杂度 | 本工程适用 |
|---|---|---|---|---|---|---|
| 1 路由 | 导航 | 高 | 弱（字符串） | 中 | 低 | ✅ 已用 |
| 2 共享 Provider | 状态/数据 | 高 | ✅ | ✅ | 中 | ✅ 已用 |
| 3 get_it | 功能/服务 | 中 | ✅（注册时） | 中 | 中 | ❌ 冗余 |
| 4 Event Bus | 事件通知 | 高 | 弱 | 低 | 低 | ⚠️ 谨慎 |
| 5 依赖倒置 | 全场景 | 高 | ✅ | ✅ | 高 | ✅ 推荐 |
| 6 core_ui | 通用 UI | 中 | ✅ | ✅ | 低 | ✅ 已用 |
| 7 Widget Provider | 跨模块 UI | 高 | ✅ | ✅ | 中 | 按需 |

### 1.4 针对本工程的建议

按场景分派，不要追求"一种方案打天下"：

1. **导航**：保持 `AppRoutes` 路径契约；要拿返回值用 `context.push<T>` + `context.pop(result)`
2. **状态共享**：保持 `favoriteRepositoryProvider` 模式（方案 2/5），
   新增跨模块状态都照这个模板
3. **功能调用**：方案 5——core 定义抽象，feature 实现，app_launch override。
   绝不让 feature 互相 import
4. **UI 复用 - 通用组件**：方案 6 提到 core_ui
5. **UI 复用 - feature 私有 widget**：方案 7 用 WidgetBuilder Provider
   （目前没用到，将来需要时再加）
6. **事件通知**：优先用 Riverpod 原生（`ref.listen` + 共享 Provider）；
   只有真正的"广播事件、无明确消费者"才考虑 Stream，
   且要先想清楚能否用 Provider 状态替代

### 1.5 反模式提醒

- **跨模块通信一定要走"抽象 + 装配"**，让 feature 互相 import = 可插拔性丧失，
  违反铁律第 4 条
- **app_launch 是唯一接线点**——新增通信点必须改它，这是设计代价不是 bug；
  把它当 feature 间的"总线/连接器"
- **EventBus 在 Riverpod 项目里是 80% 反模式**：能用 `ref.listen` + 共享 Provider
  解决的，不要走总线。状态用 Provider，事件用 ref.listen，几乎不需要总线
- **Widget 跨模块复用**先想能否提到 core_ui；不能再用 WidgetBuilder Provider，
  不要让 feature 直接 import 对方 widget
- **watch vs read**：跨模块 Provider 用 `ref.read`（一次性读）或 `ref.listen`
  （副作用），慎用 `ref.watch`——除非你确实需要重建
- **不要为了"通用"提前抽象**：方案 5/7 都有接线成本，
  只 有真有第二个消费者时才从"直接调用"重构为"接口 + override"

> **总结一句话**：本工程已经有完整的通信骨架
> （路由 + 共享 Provider + core_ui），缺的只是"跨模块复用 feature 私有 widget"
> 的 WidgetBuilder Provider 模式；Event Bus 和 get_it 在 Riverpod 工程里
> 基本是反模式，不要引入。

---

## 二、Android (Hilt) 与 Swift (Swinject) 三平台对照

### 2.1 装配点的对照（核心心智先对齐）

| 平台 | 装配机制 | 时机 | 类型安全 |
|---|---|---|---|
| Flutter (本工程) | app_launch override | `main()` 运行时 + provider 编译期生成 | 高 |
| Android (Hilt) | `@Module` + `@Binds`/`@Provides` | 编译期生成 Dagger 图 | 最高（编译期图检查） |
| Swift (Swinject) | `Container.register` / `resolve` | App 启动手动注册 | 中（运行时才报错） |

三平台抽象同构：**core 定义抽象 → feature 实现 → 装配点注入实现**。
差别只在"装配是编译期生成图"还是"运行时 Container"。

### 2.2 Android (Hilt + Kotlin)

#### 架构假设（与本项目 1:1 对照）

- 多 Gradle module：`:app` / `:feature:home` / `:feature:detail` /
  `:feature:favorite` / `:core:domain` / `:core:network` / `:core:ui`
- `:core:domain` = 纯 Kotlin 接口/模型，等价本工程的 core_domain
- feature 模块依赖 `:core:domain`，**不互相依赖**
- Hilt 在编译期生成 Dagger component，相当于"自动生成的 app_launch"

#### 场景 A：导航

- Compose Navigation：`navController.navigate("detail/123")`，
  路径常量集中放 `:core:launch` 的 `object AppRoutes`
- 路径参数用 `NavType`，返回结果用 `SavedStateHandle`
- XML 时代用 Safe Args Gradle 插件生成类型安全方向类
- 🍎 类比：Compose Navigation ≈ SwiftUI `NavigationStack(path:)` ≈ UIKit Router pattern

#### 场景 B/C：状态共享 + 功能调用

`:core:domain` 定义 `interface FavoriteRepository`；
`:feature:favorite` 实现并用 `@Binds` 绑定：

```kotlin
@Module @InstallIn(SingletonComponent::class)
abstract class FavoriteModule {
    @Binds @Singleton
    abstract fun bindFavoriteRepository(impl: FavoriteRepositoryImpl): FavoriteRepository
}
```

`:feature:detail` 的 ViewModel 只依赖抽象：

```kotlin
@HiltViewModel
class DetailViewModel @Inject constructor(
    private val favoriteRepo: FavoriteRepository  // 只认抽象，不 import favorite 模块
) : ViewModel() { ... }
```

Hilt 编译期把图连起来——等价于本工程的 app_launch override。

#### 场景 D：UI 复用

- 通用 Composable → `:core:ui`（MovieCard / LoadingScreen）= 本工程 core_ui
- feature 私有 Composable 跨模块复用：建 `:feature:search:api` 子模块，
  只放 `@Composable fun SearchBar(...)` 声明，其他模块依赖 api 子模块而非实现模块
- Gradle sourceset 拆分比 Swift Package 的 Public 烦一些，但能做

#### 场景 E：事件通知

- `StateFlow`（状态）/ `SharedFlow`（事件）暴露在 Repository 或 Singleton
- 订阅方 `collectAsState()` 桥接到 Compose
- 比 Stream 多了类型安全 + 协程作用域自动管理生命周期
- 反模式：`LocalBroadcastManager`（已废弃）、EventBus 库

#### Hilt 反模式

- feature 模块间 `implementation(project(":feature:other"))` — 违反可插拔
- 在 core 模块 `@Module` 但实现引用 feature 类 — 依赖反向
- 字段注入（Hilt 只支持构造函数 `@Inject`，不支持 `@Inject field`）

### 2.3 Swift (Swinject + SwiftUI)

#### 架构假设

- 多 Swift Package（`.package(url:...)`）或 CocoaPods subspec
- `CoreDomain` Package 定义 `protocol FavoriteRepository`
- feature Package 实现协议
- App target 启动构建 `Container`，注册依赖

#### 装配点（类比 app_launch）

```swift
let container = Container()
container.register(FavoriteRepository.self) { _ in
    FavoriteRepositoryImpl(...)
}
```

注入 View 用 `@Environment(\.appContainer)` 或环境注入的 Resolver，
**避免在 View 内部 `resolve()`**。

#### 场景 A：导航

- SwiftUI iOS 16+：`NavigationStack(path: $path)` + `navigationDestination(for:)`，
  路径用 enum 表达
- UIKit：`UIApplication.shared.open(url)` + URL Scheme + Router 协议
- SwiftUI 强调"路径即状态"，比 GoRouter 更声明式
- 🍎 UIKit 类比：自定义 Router 协议 + Coordinator pattern = GoRouter 的 push/pop

#### 场景 B/C：状态共享 + 功能调用

`CoreDomain` 定义协议，feature Package 实现，App 注册：

```swift
container.register(FavoriteRepository.self) { _ in
    FavoriteRepositoryImpl()
}
```

detail View 取实例：

```swift
struct DetailView: View {
    @Environment(\.appContainer) var container
    @State private var vm: DetailViewModel?

    var body: some View {
        DetailContent(vm: vm ?? DetailViewModel(
            repo: container.resolve(FavoriteRepository.self)!
        ))
    }
}
```

iOS 17+ 用 `@Observable` 类 + `@Environment` 注入，
状态变化自动重建 SwiftUI，无需显式订阅。

🍎 UIKit 类比：相当于在 `UIViewController.init(coder:)` 注入依赖，
绕开"从 AppDelegate 全局单例取"的反模式。

#### 场景 D：UI 复用

- 通用 View → `DesignSystem` Package（MovieCard / LoadingView / ErrorView）
  = 本工程 core_ui
- feature 私有 View 跨模块复用：在 feature Package 的 `Sources/Public/`
  暴露 `public struct SearchBarView: View`，其他 Package `import` 它
- 🍎 Swift Package 的 `public` 可见性控制比 Gradle sourceset 拆分顺手；
  SwiftUI 跨模块 View 比 Compose 更轻（结构体 + 值类型，无生命周期回调）

#### 场景 E：事件通知

- iOS 17+：`@Observable` 类，状态变化自动通知观察者
- Combine：`PassthroughSubject<Event, Never>` / `@Published`
- `NotificationCenter.default`（弱类型，慎用）— 类比 EventBus
- 🍎 UIKit：`NotificationCenter` = EventBus 的 iOS 等价物；
  SwiftUI 时代优先 Combine / Observation framework

#### Swinject 反模式

- 全局 `Container.shared` 单例（测试难、生命周期失控）
- View 内部到处 `resolve()`（应通过 `@Environment` 注入 Resolver）
- feature Package `import` 另一个 feature Package（违反可插拔）

### 2.4 三平台总对比

| 场景 | Flutter (本工程) | Android (Hilt) | Swift (Swinject + SwiftUI) |
|---|---|---|---|
| 装配点 | app_launch override | `@Module` + `@Binds`（编译期） | `Container.register`（运行时） |
| A 导航 | GoRouter + AppRoutes | NavController + 路径常量 / Safe Args | NavigationStack + path / Router 协议 |
| B 状态共享 | Provider override | `@Singleton` + `@Inject` VM + StateFlow | Container + `@Environment` + `@Observable` |
| C 功能调用 | core 抽象 + override | core interface + `@Binds` + `@Inject` | core protocol + resolve |
| D UI 通用 | core_ui | `:core:ui` Composable | DesignSystem View |
| D UI 私有 | WidgetBuilder Provider | `:feature:search:api` 子模块 | feature Package `Sources/Public` |
| E 事件 | ref.listen + Provider / Stream | StateFlow / SharedFlow | `@Observable` / Combine / NotificationCenter |

### 2.5 关键对照洞察

#### 1. 装配机制的三种范式

- **编译期生成**（Hilt/Dagger）：最类型安全，编译期检查图完整性；
  缺点是改一次绑定要重新编译
- **运行时 Container**（Swinject）：灵活，注册和解析分离；
  缺点是运行时才报错
- **混合**（Riverpod）：provider 代码生成（编译期）+ override 注入（运行时），
  介于两者之间

#### 2. 状态共享的心智差异（重要）

- **Riverpod**：状态本身就是 Provider，`watch` 自动订阅 — DI 和状态订阅是**同一层**
- **Hilt**：DI 只管注入，状态订阅要靠 `StateFlow` + `collectAsState` — DI 和订阅是**两层**
- **SwiftUI**：DI 注入 + `@Observable` 自动观察 — DI 和订阅也是两层，
  但编译器帮你隐藏订阅

> Android 和 Swift 在"状态共享"上必须分两层想：
> **注入（Hilt/Swinject）** + **状态订阅（Flow/Observation）**，
> Riverpod 把两层合并了。这是从 Flutter 迁移到另两个平台最容易踩的心智差异。

#### 3. UI 复用策略

- 三平台都遵循"通用 → 共享 UI module；私有 → 接口/工厂暴露"
- Swift Package 的 `Sources/Public` 天然支持可见性控制，
  比 Gradle sourceset 拆分顺手，比 Flutter 的"export 一份 dart 文件"更显式
- Flutter 的 WidgetBuilder Provider 最重量级——因为 Widget 是不可变快照
  + 状态外部化，跨模块共享 widget 还要约定状态来源

#### 4. 事件通知

- 三平台都倾向"状态优先，事件次之"
- `ref.listen` ≈ Compose `LaunchedEffect { flow.collect }` ≈ SwiftUI `.onReceive`
- `NotificationCenter` / `EventBus` / `Stream broadcast` 在各自生态里都被视为
  "谨慎使用"

### 2.6 回到本工程

本工程的 Flutter 通信模型**最接近 Hilt 设计哲学**：

- core_launch ≈ `:core:domain` 接口层
- app_launch override ≈ Hilt `@Binds` 装配
- Riverpod Provider ≈ Hilt `@Inject` + `StateFlow` 的合并体
- core_ui ≈ `:core:ui`

→ 迁移到 Android Hilt 几乎是 1:1 对照，学习曲线最短；
迁移到 Swinject 则多一步"把状态订阅从 DI 中拆出来交给 `@Observable`"。

---

## 三、强类型路由 + 回调返回值三平台 demo

### 3.1 设计思路先对齐

字符串路由的两个痛点：

1. 拼路径易出错：`'/detail/$id'` 漏 `$` 运行时才崩
2. 参数类型不强：Int 还是 String 全靠约定

强类型路由的核心：**用 sealed class / enum / data class 表达 destination，
编译期检查参数**。
回调返回值的核心：**push 返回一个 Future/State，pop 时把结果写回**。

| 平台 | 路由表达 | 回调机制 |
|---|---|---|
| Flutter (GoRouter) | sealed class + path getter | `context.push<T>()` 返回 Future |
| Android (Compose Nav 2.8+) | `@Serializable` data class | SavedStateHandle + StateFlow |
| Swift (SwiftUI iOS 16+) | enum Route + `navigationDestination` | closure 注入 / `@Observable` |

### 3.2 Flutter (GoRouter) demo

#### 强类型路由（放 core_launch）

```dart
// packages/core/core_launch/lib/src/app_routes.dart

/// 强类型路由基类：编译期约束参数类型
sealed class AppRoute {
  const AppRoute();

  /// 序列化成 GoRouter 能识别的路径字符串
  String get path;
}

class HomeRoute extends AppRoute {
  const HomeRoute();
  @override
  String get path => '/';
}

/// 详情路由：id 必须是 int，拼错编译期就报错
class DetailRoute extends AppRoute {
  final int id;
  const DetailRoute(this.id);

  @override
  String get path => '/detail/$id';  // 匹配 GoRouter 的 /detail/:id
}

class SearchRoute extends AppRoute {
  final String query;
  const SearchRoute(this.query);

  @override
  String get path => '/search?query=${Uri.encodeQueryComponent(query)}';
}
```

#### GoRouter 配置不变（仍按字符串路径注册）

```dart
final router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, __) => HomeScreen()),
  GoRoute(
    path: '/detail/:id',
    builder: (_, state) {
      final id = int.parse(state.pathParameters['id']!);
      return DetailScreen(id: id);
    },
  ),
  GoRoute(
    path: '/search',
    builder: (_, state) {
      final q = state.uri.queryParameters['query'] ?? '';
      return SearchScreen(query: q);
    },
  ),
]);
```

#### 调用 + 接收回调

```dart
// home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      child: Text('打开详情'),
      onPressed: () async {
        // ✅ 强类型：DetailRoute(123) 编译期检查 id 类型
        // ✅ 回调：push<bool?> 返回 Future，等 pop 时拿到值
        final result = await context.push<bool?>(const DetailRoute(123).path);
        if (result == true) {
          ref.read(homeControllerProvider.notifier).refresh();
        }
      },
    );
  }
}
```

#### 详情页返回结果

```dart
class DetailScreen extends ConsumerWidget {
  final int id;
  const DetailScreen({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      child: Text('收藏成功，返回'),
      onPressed: () => context.pop(true),  // 结果回传给 push 调用方
    );
  }
}
```

### 3.3 Android (Compose Navigation 2.8+) demo

#### 强类型路由（kotlinx-serialization）

```kotlin
// :core:launch/Route.kt

// Kotlin 2.0 + Compose Navigation 2.8.0+ 用 @Serializable data class 表达路由
@Serializable sealed interface Route

@Serializable data object HomeRoute : Route

// ✅ 强类型：id 编译期就是 Int
@Serializable data class DetailRoute(val id: Int) : Route

@Serializable data class SearchRoute(val query: String) : Route
```

#### NavHost 注册（类型安全，无需手写路径）

```kotlin
@Composable
fun AppNavHost(navController: NavController) {
    NavHost(navController, startDestination = HomeRoute) {
        composable<HomeRoute> { HomeScreen(navController) }

        // toRoute<DetailRoute>() 自动反序列化参数
        composable<DetailRoute> { backStackEntry ->
            val args: DetailRoute = backStackEntry.toRoute()
            DetailScreen(id = args.id, navController = navController)
        }

        composable<SearchRoute> { backStackEntry ->
            val args = backStackEntry.toRoute<SearchRoute>()
            SearchScreen(query = args.query)
        }
    }
}
```

#### 调用 + 接收回调

```kotlin
@Composable
fun HomeScreen(navController: NavController) {
    // 监听从详情页回来的结果（StateFlow 自动重建 Composable）
    val result by (navController.currentBackStackEntry?.savedStateHandle
        ?.getStateFlow<Boolean?>("favorite_result", null))
        ?.collectAsState() ?: remember { mutableStateOf(null) }

    Button(onClick = {
        // ✅ 强类型：DetailRoute(id=123) 编译期检查
        navController.navigate(DetailRoute(id = 123))
    }) { Text("打开详情") }

    LaunchedEffect(result) {
        if (result == true) {
            homeViewModel.refresh()  // 详情页 setResult(true) 后自动触发
        }
    }
}
```

#### 详情页返回结果

```kotlin
@Composable
fun DetailScreen(id: Int, navController: NavController) {
    Button(onClick = {
        // 把结果写回上一个 back stack entry 的 SavedStateHandle
        navController.previousBackStackEntry
            ?.savedStateHandle?.set("favorite_result", true)
        navController.popBackStack()
    }) { Text("收藏成功，返回") }
}
```

> Android 没有像 Flutter `push<T>` 那样的"等 pop 返回值"原生 API，
> 标准做法就是 SavedStateHandle + StateFlow 响应式。

### 3.4 Swift (SwiftUI NavigationStack iOS 16+) demo

#### 强类型路由（enum + associated value）

```swift
// Sources/CoreLaunch/Route.swift

// ✅ 强类型：associated value 编译期检查
enum Route: Hashable {
    case home
    case detail(id: Int)
    case search(query: String)
}
```

#### NavigationStack 注册（switch 穷尽匹配）

```swift
@State private var path = NavigationPath()  // 或 [Route]()

NavigationStack(path: $path) {
    HomeScreen()
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .home:           HomeScreen()
            case .detail(let id):  DetailScreen(id: id) { result in
                // 详情页返回时回调，处理结果
                if result { /* 刷新 */ }
            }
            case .search(let q):   SearchScreen(query: q)
            }
        }
}
```

#### 调用

```swift
Button("打开详情") {
    path.append(Route.detail(id: 123))  // ✅ 强类型 push
}
```

#### 详情页返回结果（closure 注入，最 idiomatic）

```swift
struct DetailScreen: View {
    let id: Int
    let onComplete: (Bool) -> Void   // 回调 closure
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("收藏成功，返回") {
            onComplete(true)  // 回调通知调用方
            dismiss()         // SwiftUI 自己管理 pop
        }
    }
}
```

#### iOS 17+ 替代方案（@Observable 状态共享，跨多层用）

```swift
@Observable
class AppModel {
    var pendingDetailResult: Bool?  // 全局可观察状态
}

struct HomeScreen: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        // ...
        .onChange(of: appModel.pendingDetailResult) { _, newValue in
            if newValue == true { /* 刷新 */ }
        }
    }
}
```

🍎 UIKit 类比：UIKit 没有"路由系统"，标准做法是自定义 `Router` 协议 + enum Route；
详情页返回结果用 closure 或 delegate；
`@Environment(\.dismiss)` 等价 `dismiss(animated:completion:)`。

### 3.5 三平台对照总结

| 维度 | Flutter | Android | Swift |
|---|---|---|---|
| 路由表达 | sealed class | `@Serializable` data class | enum Route |
| 类型检查 | 编译期（sealed 穷尽） | 编译期（kotlinx-serialization） | 编译期（enum switch 穷尽） |
| 调用 | `context.push(route.path)` | `navController.navigate(DetailRoute(123))` | `path.append(.detail(id: 123))` |
| 回调返回值 | `push<T>` 返回 Future | SavedStateHandle + StateFlow | closure 注入 / `@Observable` |
| 异步等待 | `await push<T>()` | `collectAsState` 响应式 | `onChange` 响应式 |
| 心智模型 | Future + pop | 响应式状态 | 响应式状态 / closure |

#### 关键差异

1. **Flutter 是命令式 Future 风格**：push 返回 Future，await 拿值，最像同步代码
2. **Android 是响应式 State 风格**：没有 Future API，用 SavedStateHandle + StateFlow
   桥接到 Compose
3. **Swift 是 closure 风格**：iOS 没有等 pop 返回值的 API，标准做法是 push 时就注入
   回调 closure；iOS 17+ 也可以用 `@Observable` 状态共享（适合跨多层）

### 3.6 反模式（三平台通用）

- ❌ 字符串拼接 `'/' + id.toString()`：拼错运行时才崩
- ❌ GoRouter 用 `go` 而不是 `push`：`go` 不返回 Future，无法拿返回值
- ❌ Android 在 ViewModel 里持有 `navController`：应留在 Composable 层
- ❌ Swift 用全局 singleton 传结果：应走 closure 或 `@Observable`
- ❌ Swift 用 NotificationCenter 传返回值：closure 显式且类型安全，远胜广播

#### 针对本工程的选型建议

- **GoRouter 官方的 typed_routes 包**（experimental）：能像 Android 一样用注解生成
  强类型路由，但 API 不稳定
- **手写 sealed class（推荐）**：稳定、零依赖、和本工程的状态管理风格一致
  （已经用 sealed class 表达 Loading/Success/Error）
- **回调用 `push<T>` + `pop(value)`**：GoRouter 原生支持，
  比另开 StateFlow 通道简单

---

## 四、心智模型总结

### 4.1 跨模块通信的统一原则

无论 Flutter / Android / Swift，跨模块通信遵循同一原则：

1. **core 定义抽象**（接口/协议/sealed class）
2. **feature 实现**
3. **装配点注入**（app_launch / Hilt @Binds / Container.register）
4. **feature 之间禁止直接 import**

### 4.2 三平台通信骨架对照

| 角色 | Flutter (本工程) | Android (Hilt) | Swift (Swinject) |
|---|---|---|---|
| 契约层 | core_launch / core_domain | `:core:domain` | `CoreDomain` Package |
| 装配点 | app_launch override | `@Module` + `@Binds` | `Container.register` |
| 装配时机 | main() 运行时 | 编译期 | App 启动 |
| DI + 状态 | Riverpod Provider（合并） | Hilt `@Inject` + `StateFlow`（分离） | Swinject + `@Observable`（分离） |
| 通用 UI | core_ui | `:core:ui` | `DesignSystem` Package |
| 私有 UI 复用 | WidgetBuilder Provider | feature api 子模块 | feature Package `Sources/Public` |
| 路由契约 | AppRoutes + GoRouter | AppRoutes + NavController | Route enum + NavigationStack |
| 事件通知 | ref.listen + Provider | StateFlow/SharedFlow | `@Observable` / Combine |
| 反模式 | feature 互相 import / EventBus | feature project 直依赖 | feature Package 互相 import |

### 4.3 学习路径建议

1. **第一步**：吃透本工程的 `favoriteRepositoryProvider` 模式
   （core 抽象 + app_launch override），这是方案 5 的标准实现，
   也是 Hilt `@Binds` 的镜像
2. **第二步**：迁移心智到 Android——core 抽象对应 `:core:domain` 接口，
   app_launch override 对应 `@Module + @Binds`，几乎 1:1
3. **第三步**：迁移心智到 Swift——多一步"把状态订阅从 DI 拆出来交给 `@Observable`"
4. **第四步**：强类型路由改造本工程的 `AppRoutes` 为 sealed class，
   保留 path getter 不破坏 GoRouter 配置

### 4.4 关键警示

- **Riverpod 把 DI 和状态订阅合并了**——这是迁移到 Android/Swift 最大的心智差异
- **EventBus / NotificationCenter / Stream broadcast 都是"谨慎使用"**——
  能用响应式状态解决的不要走广播
- **不要为了"通用"提前抽象**——只有真有第二个消费者时才从"直接调用"
  重构为"接口 + override"
- **app_launch / Hilt @Module / Container 是唯一接线点**——
  这是可插拔架构的设计代价，不是 bug

---

## 附录：术语对照速查

| 概念 | Flutter | Android | Swift |
|---|---|---|---|
| DI 容器 | Riverpod ProviderScope | Hilt Component | Swinject Container |
| 注入 | ref.read / 参数注入 | `@Inject constructor` | `container.resolve` / `@Environment` |
| 装配 | override | `@Binds` / `@Provides` | `container.register` |
| 状态订阅 | `ref.watch` | `collectAsState` | `@Observable` 自动 |
| 副作用订阅 | `ref.listen` | `LaunchedEffect { collect }` | `.onReceive` / `.onChange` |
| 单例 scope | 默认全局 | `@Singleton` | `container.shared`（反模式） |
| View scope | `autoDispose` | `@HiltViewModel` | `@StateObject` (iOS 16-) |
| 状态机 | sealed class | sealed class | enum + associated value |
| 路由 | GoRouter | NavController | NavigationStack |
| 强类型路由 | sealed class Route | `@Serializable` data class | enum Route |
| 返回值回调 | `context.push<T>` + `pop(value)` | SavedStateHandle + StateFlow | closure / `@Observable` |
