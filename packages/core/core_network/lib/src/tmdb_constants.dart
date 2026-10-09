/// =============================================================================
/// TmdbConstants —— TMDB 全局常量
/// =============================================================================
///
/// 对标 Android 工程 common-data 模块的 `Constants` object
/// （TMDB_BASE_URL / TMDB_IMAGE_BASE_URL / DEFAULT_LANGUAGE）。
/// Flutter 版把常量并入 core_network（common-data 只有这一个文件，单独建包过重，
/// 在 AGENTS.md 中记录了这个合并决策）。
///
/// 【为什么 access token 不在这里？】
///   硬编码 token 进源码会被反编译拿到。本工程 token 的数据链路：
///     `flutter run --dart-define=TMDB_API_KEY=<jwt>`
///       → `const String.fromEnvironment('TMDB_API_KEY')`（编译期常量，= BuildConfig；
///         define 名沿用历史，实际承载 TMDB v4 Bearer access token/JWT）
///       → app 壳 ProviderScope 覆写 tmdbApiKeyProvider（= Hilt @Named 注入）
///       → TmdbClient 构造时拿到 token，请求时放进 `Authorization: Bearer <token>`
///
/// 🍎 UIKit 类比：.xcconfig 里定义 API Base URL，Info.plist 注入；
///    密钥不进代码仓库。
abstract final class TmdbConstants {
  TmdbConstants._();

  /// TMDB v3 API 基础地址（不含末尾 '/'，调用方拼 "$baseUrl$path"）。
  /// /3 是 TMDB 的 API 版本号。
  static const String baseUrl = 'https://api.themoviedb.org/3';

  /// 图片基础 URL，完整规则：{imageBaseUrl}/{尺寸}/{相对路径}
  /// 例：https://image.tmdb.org/t/p/w500/abc.jpg
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  /// 默认语言：zh-CN 简体中文（TMDB 返回中文标题/简介，无中文回退英文）。
  static const String defaultLanguage = 'zh-CN';
}
