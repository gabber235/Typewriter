import "package:typewriter_panel/typewriter_panel.dart";

/// Presents connection state and, when offline, the age of the last sighting.
///
/// The relative time is recomputed on a schedule owned by this widget. Supply
/// [lastSeen] when an offline value should be more useful than `Never`.
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

  /// Whether the subject is currently considered connected.
  final bool isOnline;

  /// The last observed connection time, used only when [isOnline] is false.
  final DateTime? lastSeen;
  final Color? dotColor;
  final Color? textColor;
  final double dotSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final description = lastSeen?.describeRelativeTo(now: now);
    final effectiveDotColor =
        dotColor ?? (isOnline ? context.colors.online : context.colors.offline);
    final effectiveTextColor =
        textColor ?? Surface.secondaryForegroundOf(context);

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
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: fontSize, color: effectiveTextColor),
        ),
      ],
    );
  }
}
