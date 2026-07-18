// panel/lib/widgets/generic/components/empty_state.dart
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";

/// A reusable empty state widget used across the organization members and
/// join‑request screens. It displays an optional icon, a title and a short
/// description, and optionally a button with a callback.
///
/// The widget is deliberately small – it does not contain any animation or
/// heavy assets – because the existing `EmptyScreen` already provides a richer
/// animated version for full‑screen use‑cases. `EmptyState` is intended for
/// inline use inside tables or lists where a compact representation is needed.
class EmptyState extends HookConsumerWidget {
  const EmptyState({
    required this.title,
    required this.description,
    this.icon,
    this.buttonText,
    this.onPressed,
    super.key,
  });

  /// Main title shown in a larger font.
  final String title;

  /// Short description placed below the title.
  final String description;

  /// Optional icon identifier from the `Icones` widget (Iconify). If null,
  /// no icon is displayed.
  final String? icon;

  /// Optional button label. When provided the button is shown.
  final String? buttonText;

  /// Callback for the button press. Ignored when `buttonText` is null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Icones(
                    icon!,
                    size: 48,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              if (buttonText != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icones(Fa6Solid.plus),
                  label: Text(buttonText!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
