import "package:flutter/material.dart";

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
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(icon: icon, tooltip: tooltip, onPressed: onPressed),
    );
  }
}
