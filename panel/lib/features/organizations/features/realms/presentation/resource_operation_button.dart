import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders an operation affordance with its authoritative disabled reason.
class ResourceOperationButton extends StatelessWidget {
  const ResourceOperationButton({
    required this.presentation,
    this.disabledReason,
    this.onInvoke,
    super.key,
  });

  final skir.OperationPresentation presentation;
  final String? disabledReason;
  final VoidCallback? onInvoke;

  @override
  Widget build(BuildContext context) {
    final onPressed = disabledReason == null ? onInvoke : null;
    final destructive = presentation.tone == skir.HeaderActionTone.destructive;
    final scheme = Theme.of(context).colorScheme;
    final icon = presentation.icon.isEmpty
        ? null
        : Icones(presentation.icon, size: 16);
    final label = Text(
      presentation.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final button = switch (presentation.variant) {
      skir.ButtonVariant.filled => FilledButton.icon(
        style: destructive
            ? FilledButton.styleFrom(
                foregroundColor: scheme.onError,
                backgroundColor: scheme.error,
              )
            : null,
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
      skir.ButtonVariant.text => TextButton.icon(
        style: destructive
            ? TextButton.styleFrom(foregroundColor: scheme.error)
            : null,
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
      _ => OutlinedButton.icon(
        style: destructive
            ? OutlinedButton.styleFrom(foregroundColor: scheme.error).copyWith(
                side: WidgetStateProperty.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.disabled)
                        ? scheme.onSurface.withValues(alpha: 0.12)
                        : scheme.error,
                  ),
                ),
              )
            : null,
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
    };
    return Tooltip(
      message: disabledReason ?? presentation.description,
      child: button,
    );
  }
}
