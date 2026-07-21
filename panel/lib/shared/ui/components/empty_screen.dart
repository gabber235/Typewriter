import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EmptyScreen extends HookConsumerWidget {
  const EmptyScreen({
    required this.title,
    this.small = false,
    this.buttonText,
    this.onPressed,
    super.key,
  }) : super();

  final bool small;
  final String title;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (!small) const Spacer(),
        Expanded(
          flex: 2,
          child: const RiveAsset(
            asset: "assets/cute_robot.riv",
            stateMachineName: "Motion",
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: small ? 20 : 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: small ? 12 : 24),
        if (buttonText != null)
          FilledButton.icon(
            label: Text(buttonText ?? ""),
            onPressed: onPressed,
            icon: const Icones(Fa6Solid.plus),
          ),
        if (!small) const Spacer(),
      ],
    );
  }
}
