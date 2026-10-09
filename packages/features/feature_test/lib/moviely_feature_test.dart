/// moviely_feature_test —— test 模块统一出口
///
/// 对外暴露两样东西：
///   ① TestFeatureModule（装配入口，app_launch 聚合器 import 它）
///   ② TestScreen（页面本体，后续 example 独立调试 app 使用）
/// data/presentation 内部文件按需 src 引入。
library;

export 'src/launch/test_feature_module.dart';
export 'src/presentation/test_screen.dart';
