import "package:typewriter_panel/typewriter_panel.dart";

/// An icon action intended for the trailing edge of an input or query field.
///
/// It owns the small inset required by the panel's input layout and delegates
/// enabled state and activation semantics to an icon [Button]. The [tooltip]
/// names the action, since the icon alone is not discoverable.
class InputIconButton extends StatelessWidget {
  const InputIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: context.spacing.space1),
      child: Button(
        face: ButtonFace.icon,
        icon: icon,
        label: tooltip,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
