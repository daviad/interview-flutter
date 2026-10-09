import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'test_state.dart';

part 'test_controller.g.dart';

/// =============================================================================
/// imagePickerProvider —— ImagePicker 实例的注入点
/// =============================================================================
///
/// 为什么不直接在 Controller 里 `ImagePicker()`？
///   遵循工程约定「抽象/外部依赖通过 Provider 绑定」：生产环境绑定真实插件；
///   widget/单元测试里可以 `imagePickerProvider.overrideWithValue(假实例)`
///   替换，测试不弹真实相册、不依赖平台通道。
///
/// 🍎 UIKit 类比：依赖注入容器注册 PHPickerViewController 的工厂，
///    测试时注入 mock 工厂（≈ Hilt @Provides 提供图片选择器）。
/// 🍎 SwiftUI 类比：Environment 里注入一个 PickerService 协议，预览换假实现。
@riverpod
ImagePicker imagePicker(Ref ref) => ImagePicker();

/// =============================================================================
/// TestController —— test 模块 MVI 中枢（对标 TestViewModel.kt）
/// =============================================================================
///
/// 【@riverpod 是什么？】
///   riverpod_generator 的代码生成注解。写
///   `@riverpod class TestController extends _$TestController`，
///   build_runner 会生成 testControllerProvider（页面用 ref.watch 订阅）。
///
/// 【当前业务】
///   build() 无首载数据，直接进入 Success（imagePath=null，显示占位），
///   并在 Android 上用 retrieveLostData 恢复「选图时进程被杀」的遗留结果；
///   [pickImage] 调 image_picker 打开系统相册，成功后把照片本地路径
///   写进 TestSuccess，页面 watch 到新状态自动重建展示图片。
///
/// 🍎 UIKit 类比：DI 容器生成的 ObservableObject，
///    state 变化触发监听回调刷新界面（≈ @Published）。
/// 🍎 SwiftUI 类比：@MainActor final class TestViewModel: ObservableObject {
///    @Published var state: TestState = .success }
@riverpod
class TestController extends _$TestController {
  /// build() = 初始状态。无数据要加载，直接进入 Success（尚未选图）。
  ///
  /// Android 专属副作用：调起相册后本 App 退到后台，低内存时进程可能被系统
  /// 杀掉，选图结果无法通过正常的 await 返回。image_picker 官方要求启动时
  /// 用 retrieveLostData() 把「丢失的结果」捞回来，这里在首帧后检查一次。
  /// 注意：build() 执行期不能直接读写 state（工程铁律），用 Future.microtask
  /// 延迟到当前帧结束后执行。
  @override
  TestState build() {
    Future.microtask(_restoreLostImageOnAndroid);
    return const TestSuccess();
  }

  /// Android 进程被杀后的选图结果恢复。
  ///
  /// 🍎 UIKit 类比：iOS 上 PHPicker 跑在独立进程，不会因内存杀掉宿主 App；
  ///    Android 的相册是另一个 App 的 Activity，宿主退后台后可能被回收，
  ///    类似 Android ViewModel onSaveInstanceState 的「数据抢救」机制。
  /// 正常启动 / 其他平台 retrieveLostData() 返回空 response，直接忽略。
  Future<void> _restoreLostImageOnAndroid() async {
    // foundation 的平台判断：只在物理 Android 上执行（web/桌面/iOS 无此机制）
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final LostDataResponse response = await ref
          .read(imagePickerProvider)
          .retrieveLostData();

      // isEmpty = 没有待恢复的数据（绝大多数正常启动走这里）
      if (response.isEmpty) {
        return;
      }

      // 当前会话已经成功选过图则不覆盖（避免恢复数据顶掉新选择）
      final current = state;
      if (current is TestSuccess && current.imagePath != null) {
        return;
      }

      final XFile? file = response.file;
      if (file != null) {
        debugPrint('[TestController] 恢复进程被杀前选择的照片：${file.path}');
        state = TestSuccess(imagePath: file.path);
      } else if (response.exception != null) {
        state = TestError('选择照片失败：${response.exception!.code}');
      }
    } catch (e) {
      // 恢复流程本身失败不影响正常使用，只记日志、不进 Error 态
      debugPrint('[TestController] 恢复丢失照片失败（忽略）：$e');
    }
  }

  /// 打开系统相册选择一张照片。
  ///
  /// 流程（全程 async/await，不写回调地狱）：
  ///   1. image_picker.pickImage 拉起平台选择 UI：
  ///      - Android/iOS：系统相册（Photo Picker / PHPicker）
  ///      - Windows 桌面：系统文件打开对话框（image_picker 桌面端基于
  ///        file_selector，只支持选图库文件、不支持相机）
  ///   2. 用户取消 → 返回 null，这是正常操作而非错误，保持当前状态
  ///   3. 选中 → 把 XFile.path（本地文件绝对路径）写进 Success 状态
  ///   4. 插件/权限异常 → 进入 Error 状态，页面展示错误信息并可重试
  Future<void> pickImage() async {
    try {
      final picker = ref.read(imagePickerProvider);
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      // 用户取消选择：file 为 null，不刷新页面
      if (file == null) {
        debugPrint('[TestController] 用户取消了照片选择');
        return;
      }

      debugPrint('[TestController] 已选择照片：${file.path}');
      state = TestSuccess(imagePath: file.path);
    } catch (e) {
      // 权限被拒 / 平台通道异常等：进入 Error 态，由 UI 呈现并提供重试
      debugPrint('[TestController] 选择照片失败：$e');
      state = TestError('选择照片失败：$e');
    }
  }
}
