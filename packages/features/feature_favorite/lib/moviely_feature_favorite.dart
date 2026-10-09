/// moviely_feature_favorite —— 收藏模块统一出口
///
/// 对外暴露：
///   ① FavoriteFeatureModule（装配入口，app_launch 聚合器 import 它）
///   ② FavoriteScreen（收藏列表页）
///   ③ favoriteRepositoryProvider（跨模块共享：feature_detail import 它
///     做收藏切换；feature_favorite 自己的页面也用它读列表）
///
/// 【关于 feature 间共享数据 Provider】
///   铁律 4 禁止跨 feature import **页面**（用 AppRoute 路径跳转），
///   但**数据 Provider** 的共享是允许的（等价 Android 版从 data-db 模块
///   共享 FavoriteDao）。本工程为简化把 Repository 放在 feature_favorite，
///   detail import 本包只取 Provider，不 import 任何 Screen。
library;

export 'src/data/favorite_repository.dart';
export 'src/launch/favorite_feature_module.dart';
export 'src/presentation/favorite_screen.dart';
