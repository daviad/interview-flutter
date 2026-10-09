import 'package:flutter/material.dart';

/// =============================================================================
/// LoadingView —— 全屏加载态（对标 Compose 版 LoadingView：居中转圈）
/// =============================================================================
///
/// 🍎 UIKit 类比：全屏蒙一个 UIActivityIndicatorView；
/// 🍎 SwiftUI 类比：ProgressView() 撑满容器。
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
