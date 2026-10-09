import 'package:flutter/material.dart';

/// =============================================================================
/// ErrorView —— 全屏错误态 + 重试按钮（对标 Compose 版 ErrorView）
/// =============================================================================
///
/// MVI 的 Error 状态渲染：错误文案 + 「重试」按钮。
/// onRetry 回调由页面接到 Controller 的刷新方法（= 调 sendIntent(Refresh)）。
///
/// 🍎 UIKit 类比：错误占位 View 上放一个 UIButton，target/action 触发重试。
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
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
