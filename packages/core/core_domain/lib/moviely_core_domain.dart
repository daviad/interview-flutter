/// moviely_core_domain —— 领域层统一出口（barrel 文件）
///
/// 对标 component-moviely/common/common-domain 模块。
/// 其他包只允许 import 本文件，不直接 import src/ 内部文件
/// （等价 Kotlin 里只暴露包级公开 API、内部实现放 internal）。
library;

export 'src/models/movie.dart';
export 'src/models/movie_detail.dart';
