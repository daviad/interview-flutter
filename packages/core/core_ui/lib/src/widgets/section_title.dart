import 'package:flutter/material.dart';

/// =============================================================================
/// SectionTitle —— 区块标题（「热门电影」「正在上映」）
/// =============================================================================
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
