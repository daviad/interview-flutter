/// =============================================================================
/// TestState —— test 模块 MVI 状态（sealed 三态）
/// =============================================================================
///
/// 当前业务：从相册选一张照片并在页面展示。三态分工：
///   - Loading：预留给未来的网络请求/异步初始化首帧
///   - Error  ：选择照片失败（如权限被拒、插件异常），承载错误信息
///   - Success：页面正常展示态，[TestSuccess.imagePath] 保存选中照片的
///              本地文件路径；null = 还没选（显示占位提示）
///
/// Dart 3 的 sealed class：子类数量固定，UI switch 必须穷尽所有分支，
/// 漏写一个编译器直接报错。
///
/// 【为什么只存路径（String?）而不是图片对象？】
///   image_picker 返回的 XFile 是插件类型，让状态依赖插件会降低可测试性；
///   路径是纯字符串（等价 Android 拍照相册回调里的 Uri.path / iOS 的文件 URL），
///   UI 拿到路径后用 Image.file(File(path)) 自行解码渲染，职责更清晰。
///
/// 🍎 UIKit 类比：一个基类 + Loading/Error/Success 三个子类，
///    View 根据 state 类型 switch 渲染（类似 enum 关联值状态机）。
/// 🍎 SwiftUI 类比：enum TestState { case loading; case error(String);
///    case success(imagePath: String?) }
sealed class TestState {
  const TestState();
}

/// 加载中（后续接网络请求时使用）
class TestLoading extends TestState {
  const TestLoading();
}

/// 加载/操作失败（当前承载「选择照片失败」的错误信息）
class TestError extends TestState {
  const TestError(this.message);

  final String message;
}

/// 页面正常展示态。
/// [imagePath] 为 null 表示尚未选择照片（显示占位提示）；
/// 非 null 时页面用 Image.file 展示该路径对应的本地图片。
class TestSuccess extends TestState {
  const TestSuccess({this.imagePath});

  final String? imagePath;
}
