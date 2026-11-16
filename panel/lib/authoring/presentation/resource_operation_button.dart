import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders an operation's inspector button in its [presentation]: label,
/// icon, tone and emphasis, with its authoritative disabled reason. It presses the
/// operation's [command], the same one its key and menu entry press, so a
/// declared confirmation holds.
class ResourceOperationButton extends StatelessWidget {
  const ResourceOperationButton({
    required this.presentation,
    required this.command,
    this.disabledReason,
    super.key,
  });

  /// The operation as the pane shows it: its emphasis is the declared one,
  /// or flat when the pane already has a filled button.
  final skir.OperationPresentation presentation;
  final ActionShortcut command;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final destructive = presentation.tone == skir.HeaderActionTone.destructive;
    final face = presentation.emphasis.inPanel.face;
    final color = !destructive
        ? null
        : face == ButtonFace.filled
        ? context.colors.danger
        : context.colors.dangerText;
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
