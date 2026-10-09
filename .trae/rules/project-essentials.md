# 项目铁律（Trae 规则）— Moviely Flutter 组件化工程

> 详细背景见根目录 `AGENTS.md` 与 `docs/skill-component-shell-launch.md`。
> 本文件是每次改动必须遵守的最小规则集。

## 架构（三段式可插拔）

- `app/`（壳）→ 只依赖 `packages/app_launch`（聚合器）+ `packages/core/*`（基础包）。
- `packages/app_launch/` 是**全工程唯一**可以 import 具体 `moviely_feature_*` 的包，
  也承担 SharedPreferences 等异步初始化 + 注入 `favoriteRepositoryProvider`。
- `packages/features/*` 是业务模块，结构：`src/launch`（FeatureModule 装配入口）、
  `src/data`（DTO/Api 抽象/Client/Provider）、`src/presentation`（sealed State +
  @riverpod Controller + Screen）、`example/`（独立调试 app）。
- `core_launch` 定义 `FeatureModule` 协议、`featureModulesProvider`（默认空列表）、
  `AppRoute` sealed class（`HomeRoute`/`SearchRoute`/`FavoriteRoute`/`TestRoute`/
  `DetailRoute(id)`）作为**唯一**路由契约：
  - 每个子类自带 `path` 字符串（路径跟类型走，不再有独立字符串常量类）；
  - `AppRoute.tabs` 静态列表声明底部 tab 路由及其顺序；
  - `DetailRoute.pathTemplate`（`/detail/:id`）给 GoRouter 注册参数化路由，
    `DetailRoute(id).path` 给导航用；
  - `FeatureModule.startRoute` 返回 `AppRoute`（非 String）；
  - 调用方 `context.push(DetailRoute(movie.id).path)`，编译期约束参数类型，
    GoRouter 仍按字符串 path 匹配（不引入 typed_routes experimental）。
- 当前接入的 feature：
  - `feature_home` → `/`（底部 tab 1：首页）
  - `feature_search` → `/search`（底部 tab 2：搜索，450ms debounce）
  - `feature_favorite` → `/favorite`（底部 tab 3：收藏，shared_preferences 持久化，
    暴露 `favoriteRepositoryProvider` 供 `feature_detail` 跨模块共享）
  - `feature_detail` → `/detail/:id`（压栈路由，进入后隐藏底栏；调
    `/movie/{id}?append_to_response=credits,similar`）
  - `feature_test` → `/test`（底部 tab 4：练习模块，image_picker 选择相册照片
    并在页面 Image.file 展示；Android 走系统 Photo Picker（API 33+，低版本回退
    ACTION_GET_CONTENT，均无需存储权限），含 retrieveLostData 进程被杀恢复；
    桌面端为系统文件对话框；MVI 三态）

## 底部 tab（StatefulShellRoute + MainShell）

- `app/src/router/shell_router.dart`：遍历 `featureModulesProvider`，把 path ∈
  `AppRoute.tabs` 的 GoRoute 分到 `StatefulShellRoute.indexedStack` 的 4 个
  branch，其他路由（如 `/detail/:id`）挂根层。
- `app/src/router/main_shell.dart`：`MainShell` = `Scaffold` + `NavigationBar`，
  tab 顺序与 `AppRoute.tabs` 一一对应（home/search/favorite/test）。
- 拔掉某 tab 的 feature → 该 tab 显示占位页，App 仍可运行（可插拔）。

## 禁止事项（违反即 review 打回）

1. ❌ `app/` import 任何 `moviely_feature_*`。
2. ❌ feature 包 import `moviely_app` / `moviely_app_launch`。
3. ❌ `core_*` 包 import feature 或 app_launch；业务端点/DTO 放进 core_network。
4. ❌ 跨 feature 直接 import 页面；导航只用 `AppRoutes` 路径（go_router）。
5. ❌ 源码写死 TMDB key；只走 `--dart-define=TMDB_API_KEY=`。
6. ❌ 手改 `*.g.dart`；`build()` 里直接读写 Notifier `state`（用 `Future.microtask` 延迟）。
7. ❌ 用 `print`；统一 `debugPrint`。
8. ❌ 包内自引用 package URI；包内文件用相对 import。

## 状态管理（Riverpod 3 代码生成 + MVI）

- `@riverpod class XxxController extends _$XxxController` → build_runner 生成 provider。
- 状态用 sealed class 三态（Loading/Error/Success），UI `switch` 穷尽匹配。
- `ref.watch` 订阅 / `ref.listen` 副作用（Snackbar、导航）/ 回调里 `ref.read(notifier)`。
- 测试替换依赖：`xxxProvider.overrideWithValue(Fake())`。

## 命令（Flutter 不在 PATH，先设环境变量，见 AGENTS.md 第 4 节）

- 装依赖：工作区根 `flutter pub get`。
- 代码生成：在**具体 feature 包目录** `flutter pub run build_runner build`
  （根目录跑 0 outputs；`--delete-conflicting-outputs` 已废弃不要再加）。
- 检查：工作区根 `flutter analyze` → 必须 **No issues found!**。
- 测试：具体包目录 `flutter test`。
- 运行：`flutter run -d windows --dart-define=TMDB_API_KEY=<key>`。

## 易踩坑

- Windows 需开「开发人员模式」（插件符号链接），否则 pub get/run/build 报
  "Building with plugins requires symlink support"。
- debug 网络代理已在 `core_network` 配好（模拟器 10.0.2.2:65533 / 桌面 127.0.0.1:65532），
  Dart 不读系统代理，不要去掉。代理有两处：`dioProvider`（API 请求）+
  `configureDebugHttpOverrides()`（图片等非 Dio 请求，main 里必须在
  `WidgetsFlutterBinding.ensureInitialized()` 之后调一次）。
- PowerShell 下 flutter 的 stderr 红色文字是噪音，看退出码和日志尾部。
- **TMDB 鉴权用 v4 Bearer token**（一个 JWT），走 `Authorization: Bearer <token>`
  header；❌ 不要用 `?api_key=xxx` 查询参数（那是 v3 的 32 位 key 写法，
  把 JWT 塞进去会 401）。token 仍经 `--dart-define=TMDB_API_KEY=<jwt>` 注入。
- **Android 模拟器选图（feature_test）**：新 AVD 相册为空时把图片拖进模拟器窗口；
  Photo Picker / ACTION_GET_CONTENT 均无需声明存储权限；新增原生插件后必须
  完全停掉重跑（hot reload/restart 不注册插件）；进程被杀由 retrieveLostData 恢复。

## 文件同步（强制）

- 任何**源码 / 结构 / 约定**发生变化时，必须**同步更新** AI 引导文件：
  本文件（`.trae/rules/project-essentials.md`）与根目录 `AGENTS.md`
  （含命令、路径、Provider 名、鉴权方式、易踩坑等）。
- 引导文件与代码不一致即视为铁律破坏（review 打回）。
- 改动只能局部追加 / 修正对应章节，不要删除既有架构铁律。
