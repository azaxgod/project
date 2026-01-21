import 'package:akimat_project/core/ui/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;

    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(220),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withAlpha(160),
            width: 0.5,
          ),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: compact ? 18 : 20,
          color: isDark ? Colors.amber.shade700 : scheme.primary,
        ),
      ),
    );
  }
}
