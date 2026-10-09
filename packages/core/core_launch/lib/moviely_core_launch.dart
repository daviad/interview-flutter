/// moviely_core_launch —— 组件化装配协议层统一出口
///
/// 对标 component-moviely/common/common-launch 模块。
/// 壳工程、聚合器、各 feature 三方都只认本文件导出的契约。
library;

export 'src/app_route.dart';
export 'src/feature_module.dart';
export 'src/providers.dart';
