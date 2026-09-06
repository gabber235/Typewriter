import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class StatusIndicator extends HookWidget {
  const StatusIndicator({
    required this.isOnline,
    this.lastSeen,
    this.dotColor,
    this.textColor,
    this.dotSize = 8,
    this.fontSize = 11,
    super.key,
  });

  final bool isOnline;
  final DateTime? lastSeen;
  final Color? dotColor;
  final Color? textColor;
  final double dotSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final description = lastSeen == null
        ? null
        : describeRelativeTime(value: lastSeen!, now: now);
    final effectiveDotColor =
        dotColor ?? (isOnline ? context.colors.online : context.colors.offline);
    final effectiveTextColor = textColor ?? context.colors.contentSecondary;

    useRefreshAt(
      isOnline
          ? now.add(const Duration(seconds: 10))
          : description?.nextRefreshAt ?? now,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: effectiveDotColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: dotSize * 0.75),
        Text(
          isOnline ? "Online" : description?.compact ?? "Never",
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: fontSize,
            color: effectiveTextColor,
          ),
        ),
      ],
    );
  }
}
