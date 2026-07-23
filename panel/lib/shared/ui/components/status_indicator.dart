import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/theme/theme.dart";

class StatusIndicator extends StatelessWidget {
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

  String get _lastSeenLabel {
    if (lastSeen == null) return "Never";
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return "${weeks}w ago";
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return "${months}mo ago";
    } else {
      final years = difference.inDays ~/ 365;
      return "${years}y ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDotColor =
        dotColor ?? (isOnline ? context.colors.online : context.colors.offline);
    final effectiveTextColor = textColor ?? context.colors.contentSecondary;

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
          isOnline ? "Online" : _lastSeenLabel,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: fontSize,
            color: effectiveTextColor,
          ),
        ),
      ],
    );
  }
}
