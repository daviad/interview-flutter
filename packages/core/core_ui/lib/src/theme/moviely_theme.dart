import 'package:flutter/material.dart';

/// =============================================================================
/// MovielyTheme —— 应用主题（对标 common-ui 的 MovielyTheme）
/// =============================================================================
///
/// Material 3（Material You）配色：以一个 seedColor 自动生成整套色板。
///
/// 🍎 UIKit 类比：UIAppearance / UIColor 资产目录统一全局外观；
/// 🍎 SwiftUI 类比：.tint() + 自定义 Theme 修饰符体系。
abstract final class MovielyTheme {
  MovielyTheme._();

  /// 品牌主色（电影感深蓝紫）
  static const Color _seed = Color(0xFF6750A4);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
    ),
  );
}
