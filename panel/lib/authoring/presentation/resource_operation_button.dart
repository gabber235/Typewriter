import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders an operation's inspector button in its declared emphasis, with its
/// authoritative disabled reason. It presses the operation's [command], the
/// same one its key and menu entry press, so a declared confirmation holds.
class ResourceOperationButton extends StatelessWidget {
  const ResourceOperationButton({
    required this.presentation,
    required this.command,
    this.disabledReason,
    super.key,
  });

  final skir.OperationPresentation presentation;
  final ActionShortcut command;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final destructive = presentation.tone == skir.HeaderActionTone.destructive;
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
    return CommandButton(
      command: command,
      enabled: disabledReason == null,
      hint: destructive ? "Destructive" : null,
      tooltip: disabledReason ?? presentation.description,
      face: face,
      color: color,
      icon: presentation.icon.isEmpty
          ? null
          : Icones(presentation.icon, size: 16),
      label: presentation.label,
    );
  }
}
