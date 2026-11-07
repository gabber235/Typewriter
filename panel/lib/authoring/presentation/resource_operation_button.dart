import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders an operation's inspector button in its declared emphasis, with its
/// authoritative disabled reason.
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
    final icon = presentation.icon.isEmpty
        ? null
        : Icones(presentation.icon, size: 16);
    final variant = switch (presentation.inspector) {
      skir.OperationInspector_buttonWrapper(:final value) => value,
      _ => skir.ButtonVariant.outlined,
    };
    final (face, color) = switch (variant) {
      skir.ButtonVariant.filled => (
        ButtonFace.filled,
        destructive ? context.colors.danger : null,
      ),
      skir.ButtonVariant.text => (
        ButtonFace.quiet,
        destructive ? context.colors.dangerText : null,
      ),
      _ => (
        ButtonFace.outlined,
        destructive ? context.colors.dangerText : null,
      ),
    };
    // The destructive tone is more than a colour: the hint announces it.
    return Button(
      hint: destructive ? "Destructive" : null,
      face: face,
      color: color,
      onPressed: onPressed,
      icon: icon,
      label: presentation.label,
      tooltip: disabledReason ?? presentation.description,
    );
  }
}
