import 'package:akimat_project/core/ui/widgets/animated_button.dart';
import 'package:flutter/material.dart';

/// Базовая кнопка - теперь использует AnimatedButton для единообразия
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final IconData? icon;
  final bool useBlackText;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.icon,
    this.useBlackText = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      label: label,
      onPressed: onPressed,
      isDestructive: isDestructive,
      icon: icon,
      useBlackText: useBlackText,
    );
  }
}
