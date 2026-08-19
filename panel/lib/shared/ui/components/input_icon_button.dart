import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
