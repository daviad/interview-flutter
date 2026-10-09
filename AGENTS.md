# AGENTS.md — Moviely Flutter 工程指引（AI 代理必读）

> 本工程是 Moviely 电影 App 的 Flutter 重写版，忠实复刻 Android 工程
> `component-moviely` 的**三段式可插拔组件化**架构，状态管理用 **Riverpod 3**
> （代码生成版）。代码注释面向 iOS 开发者学习 Flutter/Android，对照关系以
> 🍎 UIKit 为主、SwiftUI 为辅。

---

## 1. 架构总览（先读这个，再动代码）

```
┌────────────────────────────────────────────────────────────────┐
│ app/（壳工程，= component-moviely/app）                          │
│   main.dart：注入 API key → 遍历 module.onCreate() → runApp     │
│   src/router/shell_router.dart：GoRouter 聚合所有模块路由        │
│   ⚠️ 永不 import 任何 moviely_feature_* 包                       │
└─────────────┬──────────────────────────────────────────────────┘
              │ 只依赖聚合器 + core_*
              ▼
┌────────────────────────────────────────────────────────────────┐
│ packages/app_launch/（聚合器，= app-launch）                     │
│   lib/src/launch_bootstrap.dart：bootstrapOverrides             │
│   ⚠️ 全工程【唯一】允许 import 具体 feature 的包                  │
│   新增 feature = 这里加一行依赖 + 列表加一个实例，壳零改动        │
└─────────────┬──────────────────────────────────────────────────┘
              │ override 注入模块清单
              ▼
┌────────────────────────────────────────────────────────────────┐
│ packages/core/core_launch/（装配协议层，= common-launch）        │
│   FeatureModule 抽象（onCreate / routes / startRoute: AppRoute）│
│   AppRoute sealed class（HomeRoute/SearchRoute/FavoriteRoute/   │
│     TestRoute/DetailRoute(id)）—— 唯一路由契约：子类自带 path，  │
│     AppRoute.tabs 声明底部 tab，DetailRoute.pathTemplate 注册用  │
│   featureModulesProvider（默认空列表 = 无模块也能跑）            │
└─────────────▲──────────────────────────────────────────────────┘
              │ implements / 贡献路由（壳与 feature 互不相识）
┌────────────┴───────────────────────────────────────────────────┐
│ packages/features/feature_home/（首页业务，= feature-home）      │
│   src/launch/HomeFeatureModule  ← 装配入口                      │
│   src/data/      DTO + HomeApi 抽象 + Client + Provider         │
│   src/presentation/ sealed State + @riverpod Controller + Screen│
│   example/  独立调试 app（= standalone 源集，不进 workspace）    │
└────────────────────────────────────────────────────────────────┘

core 基础包（业务无关，feature 可依赖，它们互不依赖除 core_domain 外）：
  core_domain  纯 Dart 领域模型（Movie / MovieDetail / Cast），零 Flutter 依赖
  core_network Dio + TmdbClient（端点无关）+ 代理/鉴权 providers + HttpOverrides
  core_ui      MovielyTheme + Loading/Error/Empty/MovieCard 等组件
```

**核心心智模型**：壳只认识 `FeatureModule` 抽象；feature 只认识抽象；
聚合器是唯一「接线点」。拔掉 feature_home，壳显示「无模块接入」占位页，
照常编译运行——这就是可插拔。

## 1.1 当前接入的 feature 模块

| 包 | 路径 | 类型 | 说明 |
|---|---|---|---|
| `feature_home` | `/` | 底部 tab 1 | 首页：热门 + 正在上映 |
| `feature_search` | `/search` | 底部 tab 2 | 搜索：450ms debounce，`/search/movie` |
| `feature_favorite` | `/favorite` | 底部 tab 3 | 收藏：`shared_preferences` 持久化，
  暴露 `favoriteRepositoryProvider` 供 `feature_detail` 跨模块共享 |
| `feature_detail` | `/detail/:id` | 压栈路由 | 详情：`/movie/{id}?append_to_response=credits,similar`，
  进入后隐藏底栏，含收藏按钮 |
| `feature_test` | `/test` | 底部 tab 4 | 练习模块：image_picker 选择相册照片并 Image.file 展示；Android 走系统
  Photo Picker（API 33+，低版本自动回退 ACTION_GET_CONTENT，均无需存储权限），
  含 retrieveLostData 进程被杀恢复；桌面端弹系统文件对话框；MVI 三态 |

## 1.2 底部 tab（StatefulShellRoute + MainShell）

- `app/src/router/shell_router.dart`：遍历 `featureModulesProvider`，把 path ∈
  `AppRoute.tabs`（各 tab 路由 path：`'/' '/search' '/favorite' '/test'`）的 GoRoute 分到
  `StatefulShellRoute.indexedStack` 的 4 个 branch；其他路由（如 `/detail/:id`）
  挂根层（压栈，进入后隐藏底栏）。
- `app/src/router/main_shell.dart`：`MainShell` = `Scaffold` + `NavigationBar`，
  tab 顺序与 `AppRoute.tabs` 一一对应（home/search/favorite/test）。
- 拔掉某 tab 的 feature → 该 tab 显示占位页，App 仍可运行（可插拔）。

## 2. 依赖方向铁律（违反即架构破坏）

1. `app` **禁止** import `moviely_feature_*`（只能碰 `moviely_app_launch` 和 `moviely_core_*`）。
2. `packages/features/*` **禁止** import `moviely_app` / `moviely_app_launch`。
3. `core_*` 包**禁止** import feature 和 app_launch。
4. 跨 feature 导航只走 `AppRoute` 强类型路由契约（`context.push(DetailRoute(id).path)`），不 import 对方页面。
5. 包内文件互引用**相对 import**（`import 'home_state.dart';`），不要 import 自己的 package URI。
6. 业务端点/DTO 归 feature 私有，**不进** core_network（基础层业务无关）。

## 3. 状态管理约定（Riverpod 3 + MVI）

- 用代码生成版：`@riverpod class XxxController extends _$XxxController`，
  build_runner 生成 `xxxControllerProvider`。
- 页面是 `ConsumerWidget`：`ref.watch` 订阅状态、`ref.listen` 处理副作用
  （Snackbar/导航）、回调里 `ref.read(...notifier)` 调方法。
- MVI 三态用 **sealed class** 表达（Loading/Error/Success），`switch` 穷尽匹配；
  刷新时保留旧数据（`isRefreshing` + 一次性 `refreshMessage`）。
- 异步并发用 `Future.wait([...])`；`build()` 内**不能**直接读写 `state`
  （Notifier 未初始化），用 `Future.microtask` 延迟首载。
- 抽象接口 + Provider 绑定是测试替换点：测试里 `xxxProvider.overrideWithValue(Fake())`。

## 4. 命令与环境（⚠️ 本机 Flutter 不走系统 PATH，每个命令都要带环境变量）

Flutter SDK：`C:\Users\dxw\fvm\flutter`；Android SDK：`C:\Users\dxw\fvm\android-sdk`。
PowerShell 里先执行（或合并成一行前缀）：

```powershell
$env:APPDATA='C:\Users\dxw\fvm\home\Roaming'
$env:LOCALAPPDATA='C:\Users\dxw\fvm\home\Local'
$env:PUB_CACHE='C:\Users\dxw\fvm\pub-cache'
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
$env:ANDROID_HOME='C:\Users\dxw\fvm\android-sdk'
$env:ANDROID_SDK_ROOT='C:\Users\dxw\fvm\android-sdk'
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$flutter='C:\Users\dxw\fvm\flutter\bin\flutter.bat'
```

| 操作 | 命令（cwd） |
|---|---|
| 装依赖 | `& $flutter pub get`（工作区根） |
| 代码生成 | `& $flutter pub run build_runner build`（⚠️ 在**具体 feature 包目录**跑，根目录跑 0 outputs；不要加 `--delete-conflicting-outputs`，新版已移除该选项） |
| 静态检查 | `& $flutter analyze`（工作区根，目标 **No issues found!**） |
| 单元/widget 测试 | `& $flutter test`（在具体包目录） |
| 跑壳 app | `& $flutter run -d windows --dart-define=TMDB_API_KEY=<key>` |
| 跑 example | cwd=`packages/features/feature_home/example`，同上 |
| 构建 APK | `& $flutter build apk --debug --dart-define=TMDB_API_KEY=<key>` |

> PowerShell 会把 flutter 的 stderr 进度显示成红色 NativeCommandError 噪音，
> 用 `*> 日志文件` 重定向后看日志尾部判断成败。
> `dart.bat` 包装器缺 git 会失败，统一用 `flutter.bat pub run`。

## 5. 网络与密钥（易踩坑）

- TMDB 鉴权用 **v4 Bearer access token**（一个 JWT），由 `TmdbClient` 放进
  `Authorization: Bearer <token>` header；❌ 不要用 v3 的 `?api_key=xxx` 查询参数
  （那是 32 位 v3 key 的写法，把 JWT 塞进去会 401）。
- token 只通过编译参数注入：`--dart-define=TMDB_API_KEY=<jwt>`，
  代码里 `const String.fromEnvironment('TMDB_API_KEY')` 读取，**禁止写死进源码**。
  （define 名沿用历史叫 `TMDB_API_KEY`，实际承载的是 v4 Bearer token。）
  token 未注入时 `tmdbApiKeyProvider` 抛 `UnimplementedError` 快速失败。
- **代理**：Dart HttpClient 不读 Android 系统代理（同 KMP 的 CIO 教训）。
  debug 模式 `core_network` 已显式配代理，**两处都要**：
  - `network_providers.dart` 的 `dioProvider`：用 `IOHttpClientAdapter` 给 Dio
    设代理（覆盖 API 请求）。
  - `http_overrides.dart` 的 `configureDebugHttpOverrides()`：设置全局
    `HttpOverrides.global`，覆盖 **非 Dio** 的请求（`cached_network_image` →
    Flutter 原生 HttpClient → 图片加载）。**必须**在两个 `main.dart` 里
    `WidgetsFlutterBinding.ensureInitialized()` 之后调一次，否则海报加载失败。
  代理地址：Android 模拟器 `10.0.2.2:65533`（宿主机 portproxy → 本地 Nano
    代理 65532）、Windows 桌面 `127.0.0.1:65532`。可用
    `--dart-define=TMDB_PROXY_HOST=host:port` 覆盖。
- **Windows 开发者模式**：Flutter 插件在 Windows 上依赖符号链接，
  `flutter pub get`/`run`/`build` 报 "Building with plugins requires symlink support" 时，
  需在「设置 → 隐私和安全性 → 开发者选项」打开**开发人员模式**（或管理员权限运行）。
- **Android 模拟器选图（feature_test）**：
  - 新 AVD 相册通常是空的，Photo Picker/文件选择器里没图 → 直接把一张
    jpg/png **拖进模拟器窗口**，文件进 Download 并自动媒体扫描后才会出现。
  - image_picker 走系统 Photo Picker（API 33+）/ 回退 ACTION_GET_CONTENT，
    **无需**在 AndroidManifest 声明 READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE。
  - 新增原生插件后必须**完全停掉重跑** `flutter run`（hot reload/restart 不注册插件）。
  - 选图时 App 退后台低内存被杀：Controller 启动时调 `retrieveLostData()` 恢复。

## 6. 新增一个 feature（可插拔操作清单）

1. 建包 `packages/features/feature_xxx/`（结构抄 feature_home：`src/launch`、`src/data`、`src/presentation`、`example/`）。
2. 写 `XxxFeatureModule implements FeatureModule`（routes + 可选 onCreate）。
3. 根 `pubspec.yaml` 的 `workspace:` 加成员；包 pubspec 加 `resolution: workspace`。
4. **只在** `packages/app_launch`：pubspec 加 path 依赖 + `bootstrapOverrides` 列表加实例。
5. 跨页路由加到 `core_launch` 的 `AppRoute` sealed class（新增一个子类）。
   - 子类自带 `path` 字符串（如 `String get path => '/xxx';`）。
   - 若是**底部 tab**：把该子类实例加进 `AppRoute.tabs` 列表，同时在
     `app/src/router/main_shell.dart` 的 `_tabs` 加对应的 icon/label
     （顺序与 `AppRoute.tabs` 一一对应）。
   - 若是**压栈路由**（如详情页）：只加子类，**不**加进 `AppRoute.tabs`，
     `shell_router` 会自动归到根层。参数化路由需提供
     `static const pathTemplate = '/xxx/:param'` 给 GoRouter 注册用。
6. 补 widget 测试（Fake 数据源 override Provider）；`flutter analyze` 保持零问题。
7. 同步 `.trae/rules/project-essentials.md` 与本 `AGENTS.md` 的 feature 清单
   （第 1.1 节表格）+ `AppRoute` 路由说明（文件同步铁律，见第 8 节）。

## 7. 代码风格

- 注释用中文，关键概念对照 Android（Hilt/Ktor/Compose）并带 🍎 iOS 类比。
- 禁 `print`，用 `debugPrint`；prefer const；strict-casts 已开启。
- 不用 freezed；DTO 用 json_serializable（`@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)`）。
- 生成文件 `*.g.dart` 不手改，由 build_runner 产出。

## 8. 文件同步（强制）

- 任何**源码 / 结构 / 约定**发生变化时，必须**同步更新** AI 引导文件：
  `.trae/rules/project-essentials.md`（最小铁律集）与本文件 `AGENTS.md`
  （含命令、路径、Provider 名、鉴权方式、易踩坑等）。
- 引导文件与代码不一致即视为铁律破坏（review 打回）。
- 改动只能局部追加 / 修正对应章节，不要删除既有架构铁律。
