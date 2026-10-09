# Skill：组件化「壳-聚合器-协议」可插拔架构（Flutter / Riverpod 版）

> 适用场景：多 feature 的 Flutter App，要求 feature 可独立开发/独立调试、
> 壳工程零业务、接拔模块只改一处。本模式从 Android `component-moviely`
> （Hilt @IntoSet + ModuleLifecycle/ModuleNavigator）平移到 Flutter，
> 用 **pub workspace + Riverpod override + go_router** 落地。

---

## 1. 模式结构（四个角色）

| 角色 | 包 | Android 对照 | 职责 | 能依赖谁 |
|---|---|---|---|---|
| 壳 | `app/` | `app/` 模块 | 启动、DI 容器、生命周期分发、路由聚合 | 聚合器 + core |
| 聚合器 | `packages/app_launch/` | `app-launch/` | **唯一** import 全部 feature 的包，输出 override 清单 | core_launch + features |
| 协议层 | `packages/core/core_launch/` | `common-launch/` | 定义 `FeatureModule` 抽象、路由常量、模块清单 Provider（默认空） | 谁都不依赖（除 flutter_riverpod/go_router） |
| 业务模块 | `packages/features/feature_xxx/` | `feature-xxx/` | 实现协议、贡献页面/路由/数据 | core_*，绝不依赖壳与聚合器 |

基础包 `core_domain / core_network / core_ui` 是业务无关公共设施。

## 2. 三个关键机制

### ① 模块协议（FeatureModule）

```dart
abstract interface class FeatureModule {
  Future<void> onCreate() async {}   // 生命周期 = ModuleLifecycle.onCreate
  void onTerminate() {}
  List<RouteBase> get routes;        // 路由贡献 = ModuleNavigator.routes
  String get startRoute;             // 起始路由
}
```

### ② 模块清单（多绑定集合）

协议层声明空默认（等价 Hilt `@ElementsIntoSet emptySet()`）：

```dart
final Provider<List<FeatureModule>> featureModulesProvider =
    Provider((ref) => const <FeatureModule>[]);
```

聚合器注入真实清单（等价 Hilt `@Binds @IntoSet`）：

```dart
final List<Override> bootstrapOverrides = [
  featureModulesProvider.overrideWithValue(const [HomeFeatureModule()]),
];
```

### ③ 壳的组装（main + router）

```dart
final container = ProviderContainer(overrides: [
  if (apiKey.isNotEmpty) tmdbApiKeyProvider.overrideWithValue(apiKey),
  ...bootstrapOverrides,                 // ← feature 全在这一个变量里
]);
for (final m in container.read(featureModulesProvider)) {
  await m.onCreate();                    // 生命周期分发
}
runApp(UncontrolledProviderScope(container: container, child: const MovielyApp()));
```

```dart
final shellRouterProvider = Provider((ref) {
  final modules = ref.watch(featureModulesProvider);
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      if (modules.isEmpty)
        GoRoute(path: '/', builder: (_, _) => const NoModulePage())  // 空壳占位
      else
        for (final m in modules) ...m.routes,                        // 聚合路由
    ],
  );
});
```

## 3. feature 包标准结构（抄作业模板）

```
packages/features/feature_xxx/
├── pubspec.yaml                # resolution: workspace；只依赖 core_*
├── lib/
│   ├── moviely_feature_xxx.dart        # barrel：只导出 FeatureModule + 页面
│   └── src/
│       ├── launch/xxx_feature_module.dart  # implements FeatureModule
│       ├── data/
│       │   ├── xxx_dtos.dart         # @JsonSerializable DTO（snake, createToJson:false）
│       │   ├── xxx_api.dart          # 抽象接口（测试替换点）
│       │   ├── xxx_api_client.dart   # 实现：TmdbClient.get(path, fromJson:)
│       │   └── providers.dart        # xxxApiProvider = Provider((ref) => XxxApiClient(...))
│       └── presentation/
│           ├── xxx_state.dart        # sealed class 三态
│           ├── xxx_controller.dart   # @riverpod class XxxController extends _$XxxController
│           └── xxx_screen.dart       # ConsumerWidget：watch/listen/read
└── example/                     # 独立调试 app（不进 workspace，自带 ProviderScope）
```

## 4. MVI 数据流（feature 内部）

```
用户动作(下拉刷新/重试) ──ref.read(notifier).refresh()──▶ Controller
                                                          │ Future.wait 并发取数
                            state = Loading/Success(旧数据,isRefreshing)
                                                          ▼
ref.watch(provider) ◀── state = Success(data) / Error(msg) ──▶ UI 重建
ref.listen(provider) ──▶ refreshMessage → Snackbar（一次性副作用）
```

要点：
- 首屏失败 → 全屏 ErrorView + 重试；刷新失败 → 保留旧数据 + Snackbar。
- `build()` 不能读写 `state`（未初始化），首载用 `Future.microtask(...)` 延迟。
- 异常在 Controller catch 后转状态；网络层（TmdbClient/Dio）只抛不处理 UI。

## 5. 插拔新模块 Checklist

1. 复制 feature_home 骨架改名，实现页面与 `XxxFeatureModule`。
2. 根 `pubspec.yaml` workspace 列表加路径；包 pubspec 写 `resolution: workspace`。
3. **只改聚合器**：`app_launch/pubspec.yaml` 加 path 依赖；
   `bootstrapOverrides` 列表加 `XxxFeatureModule()`。
4. 跨模块跳转路径常量加到 `core_launch/AppRoutes`，页面只 `context.push(路径)`。
5. `example/` 可独立 run 调试；补 widget 测试（Fake Api override Provider）。
6. 验证：`flutter analyze` 零问题；把模块从聚合器注释掉 → 壳显示空占位页且可编译运行。

## 6. 常见反模式

- ❌ 壳里 `import 'package:moviely_feature_home/...'`：模块对壳必须透明。
- ❌ feature 里 import app_launch「图方便」拿 override：方向反了，立刻耦合死。
- ❌ 把业务端点写进 core_network 的 TmdbClient：基础层一旦认识业务就无法复用。
- ❌ 页面里直接 `Dio().get(...)`：绕过 DI，测试无法替换。
- ❌ 用 `Navigator.push(MaterialPageRoute(builder: DetailPage()))` 跨 feature：
  编译期强耦合；必须走路由字符串契约。
