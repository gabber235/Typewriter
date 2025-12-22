import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/hooks/timer.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class CountdownBadge extends HookWidget {
  const CountdownBadge({
    required this.endDate,
    this.urgentThreshold = const Duration(seconds: 60),
    this.onExpired,
    super.key,
  });

  final DateTime endDate;
  final Duration urgentThreshold;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = useState(endDate.difference(DateTime.now()));
    final isUrgent = remaining.value <= urgentThreshold;

    useTimer(1.seconds, (timer) {
      final duration = endDate.difference(DateTime.now());
      if (duration.isNegative) {
        remaining.value = Duration.zero;
        timer.cancel();
        onExpired?.call();
        return;
      }
      remaining.value = duration;
    }, keys: [endDate]);

    final backgroundColor = isUrgent
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHigh;
    final foregroundColor = isUrgent
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icones(
            MaterialSymbols.timer_rounded,
            size: 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(remaining.value),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) return "0:00";

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      final hourStr = hours.toString().padLeft(2, "0");
      final minuteStr = minutes.toString().padLeft(2, "0");
      final secondStr = seconds.toString().padLeft(2, "0");
      return "$days days $hourStr:$minuteStr:$secondStr";
    }

    if (duration.inHours > 0) {
      return "${duration.inHours}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
    }

    return "$minutes:${seconds.toString().padLeft(2, "0")}";
  }
}
