import "package:typewriter_panel/typewriter_panel.dart";

/// An icon action intended for the trailing edge of an input or query field.
///
/// It owns the small inset required by the panel's input layout and delegates
/// enabled state and activation semantics to [IconButton]. Supply [tooltip]
/// for actions whose icon alone is not discoverable, especially when the
/// action reports an input error or clears a query.
class InputIconButton extends StatelessWidget {
  const InputIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: context.spacing.space1),
      child: IconButton(icon: icon, tooltip: tooltip, onPressed: onPressed),
    );
  }
}
