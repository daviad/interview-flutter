/// moviely_feature_detail —— 详情模块统一出口
///
/// 对外只暴露：
///   ① DetailFeatureModule（装配入口，app_launch 聚合器 import 它）
///   ② DetailScreen（页面本体，详情 family provider 接收 movieId）
library;

export 'src/launch/detail_feature_module.dart';
export 'src/presentation/detail_screen.dart';
