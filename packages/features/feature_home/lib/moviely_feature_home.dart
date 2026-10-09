/// moviely_feature_home —— 首页模块统一出口
///
/// 对壳工程只暴露两样东西：
///   ① HomeFeatureModule（装配入口，app_launch 聚合器 import 它）
///   ② HomeScreen（页面本体，example 独立调试 app 使用）
/// data/presentation 内部文件按需 src 引入。
library;

export 'src/launch/home_feature_module.dart';
export 'src/presentation/home_screen.dart';
