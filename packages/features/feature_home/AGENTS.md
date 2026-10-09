# AGENTS.md — feature_home 模块指引

> 首页业务模块（TMDB 热门电影 + 正在上映）。架构总规则见工程根 `AGENTS.md`。
> 本文件讲「在这个包内部怎么改代码」。

## 结构

```
lib/
├── moviely_feature_home.dart          # barrel：仅导出 HomeFeatureModule / HomeScreen
└── src/
    ├── launch/home_feature_module.dart  # 装配入口：implements FeatureModule（routes/onCreate）
    ├── data/
    │   ├── home_dtos.dart               # MovieDto / MovieResponseDto（@JsonSerializable）
    │   ├── home_api.dart                # HomeApi 抽象接口 ← 测试 override 点
    │   ├── home_api_client.dart         # HomeApiClient：调 TmdbClient.get(端点)
    │   └── providers.dart               # homeApiProvider（生产绑 Client）
    └── presentation/
        ├── home_state.dart              # sealed HomeState：Loading/Error/Success
        ├── home_controller.dart         # @riverpod HomeController（MVI 中枢）
        └── home_screen.dart             # HomeScreen(ConsumerWidget) + _HomeContent
example/                                 # 独立调试 app（standalone，不进 workspace）
test/home_screen_test.dart               # widget 测试（FakeHomeApi override homeApiProvider）
```

## 改动指南

- **加接口字段**：改 `home_dtos.dart` 的 DTO（snake_case 自动映射），
  在 `toMovie()` 里映射到 `core_domain` 的 `Movie`；UI 只用 `Movie`，不用 DTO。
- **加端点**：`HomeApi` 加抽象方法 → `HomeApiClient` 实现（path 字符串在这层）
  → Controller 调用。**不要**把端点路径写进 core_network。
- **改状态/交互**：在 `home_state.dart` 加 sealed 子类或字段（copyWith 别忘了），
  Controller 里发新状态，Screen 的 `switch` 穷尽分支会被编译器提醒补全。
- **一次性消息**（Snackbar）：写进 `HomeSuccess.refreshMessage`，
  页面 `ref.listen` 统一弹；不要在 Widget 里直接调 ScaffoldMessenger。
- **跳转详情**：`context.push(AppRoutes.detailPath(movie.id))`——只用路由常量，
  详情页属于未来的 feature_detail，本包不 import 它。

## 关键坑

- 改了 `@JsonSerializable` / `@riverpod` 相关代码后，必须在**本包目录**跑
  `flutter pub run build_runner build` 重新生成 `*.g.dart`（在工作区根跑是 0 outputs）。
- Controller `build()` 内不能读写 `state`（未初始化异常）；首载用
  `Future.microtask(() => _load(...))` 延迟。
- 网络请求走 `ref.read(homeApiProvider)`，测试里 `homeApiProvider.overrideWithValue(FakeHomeApi())`，
  测试不需要 API key、不发真实请求。
- 本包**禁止** import `moviely_app` / `moviely_app_launch`（方向铁律）。
- 海报为 null 时组件走占位图标分支；widget 测试里用 null 海报避免图片加载。

## 验证命令（cwd = 本包目录；环境变量见根 AGENTS.md 第 4 节）

```powershell
& $flutter pub run build_runner build   # 生成代码
& $flutter analyze                      # 零问题
& $flutter test                         # 测试全绿
& $flutter run -d windows --dart-define=TMDB_API_KEY=<key>   # example 调试（在 example/ 目录）
```
