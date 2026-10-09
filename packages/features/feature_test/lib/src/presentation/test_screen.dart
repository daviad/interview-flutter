import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'test_controller.dart';
import 'test_state.dart';

/// =============================================================================
/// TestScreen —— test tab 页面（ConsumerWidget）
/// =============================================================================
///
/// 练习功能：点击按钮打开系统相册选择一张照片，并把照片显示在页面上。
///
/// ConsumerWidget = 能读 Provider 的 Widget：
///   ref.watch(provider) : 订阅状态，状态变化自动 rebuild
///   ref.read(provider)  : 只取值不订阅（回调里用）
///
/// MVI 数据流（注意 UI 永远不自己持有图片数据）：
///   按钮 onPressed
///     → ref.read(testControllerProvider.notifier).pickImage()
///     → Controller 调 image_picker 选图，把本地路径写进 TestSuccess
///     → ref.watch 的本页面收到新状态自动 rebuild
///     → Image.file(File(imagePath)) 解码并显示照片
///
/// 🍎 UIKit 类比：UIViewController 放一个 UIButton + UIImageView，
///    点击 present UIImagePickerController（现代是 PHPickerViewController），
///    选图回调里让 ViewModel 更新状态，再把路径交给 UIImage(contentsOfFile:)
///    生成 UIImage 塞给 imageView。Flutter 的 Image.file 就是这条链路的声明式版。
/// 🍎 SwiftUI 类比：Button 触发 viewModel.pickImage()，body 里
///    `if let path = state.imagePath { Image(path) }` 自动随状态刷新。
class TestScreen extends ConsumerWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      // sealed 三态穷尽匹配：漏写一个分支编译器直接报错
      body: switch (state) {
        TestLoading() => const Center(child: CircularProgressIndicator()),
        TestError(:final message) => _TestErrorView(
          message: message,
          // 失败态给一个重试入口，仍走同一个 Controller 方法
          onRetry: () =>
              ref.read(testControllerProvider.notifier).pickImage(),
        ),
        TestSuccess(:final imagePath) => _TestContent(
          imagePath: imagePath,
          // 回调里用 ref.read(...notifier) 调方法，不用 ref.watch
          onPickImage: () =>
              ref.read(testControllerProvider.notifier).pickImage(),
        ),
      },
    );
  }
}

/// 正常展示态：上方照片展示区（占满剩余空间）+ 下方选择按钮。
class _TestContent extends StatelessWidget {
  const _TestContent({required this.imagePath, required this.onPickImage});

  /// 选中照片的本地绝对路径；null = 尚未选择，显示占位提示。
  final String? imagePath;

  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: imagePath == null
                  ? const _ImagePlaceholder()
                  // Image.file：读本地文件系统图片（相册/文件对话框给的是本地路径）。
                  // 🍎 UIKit：UIImage(contentsOfFile:) + UIImageView(contentMode: .scaleAspectFit)
                  : Image.file(
                      File(imagePath!),
                      fit: BoxFit.contain,
                      // 文件损坏/路径失效时显示错误占位，而不是整片红屏报错
                      errorBuilder: (context, error, stackTrace) =>
                          const _ImagePlaceholder(hasError: true),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(imagePath == null ? '从相册选择照片' : '重新选择照片'),
          ),
        ],
      ),
    );
  }
}

/// 照片占位：未选择或加载失败时显示。
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.hasError = false});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasError ? Icons.broken_image_outlined : Icons.image_outlined,
          size: 80,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 12),
        Text(
          hasError ? '图片加载失败，请重新选择' : '还没有选择照片\n点击下方按钮从相册选择',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// 错误态：展示错误信息 + 重试按钮（如相册权限被拒后引导重试）。
class _TestErrorView extends StatelessWidget {
  const _TestErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
