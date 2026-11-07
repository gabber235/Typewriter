import "package:typewriter_panel/typewriter_panel.dart";

/// Waits before something happens. Never a move.
@immutable
class TypewriterTiming extends ThemeExtension<TypewriterTiming> {
  const TypewriterTiming({
    this.hoverExitDelay = const Duration(milliseconds: 180),
    this.tooltipWait = const Duration(milliseconds: 100),
    this.tooltipShow = const Duration(milliseconds: 1500),
    this.longPressDelay = const Duration(milliseconds: 180),
    this.typeAheadReset = const Duration(milliseconds: 700),
  });

  /// How long a hover opened popup stays after the pointer leaves it.
  final Duration hoverExitDelay;

  /// How long the pointer rests on a target before its tooltip shows.
  final Duration tooltipWait;

  /// How long a tooltip a touch showed stays.
  final Duration tooltipShow;

  /// How long a press is held before it counts as a long press.
  final Duration longPressDelay;

  /// How long after the last typed letter a menu's type ahead starts over.
  final Duration typeAheadReset;

  @override
  TypewriterTiming copyWith({
    Duration? hoverExitDelay,
    Duration? tooltipWait,
    Duration? tooltipShow,
    Duration? longPressDelay,
    Duration? typeAheadReset,
  }) {
    return TypewriterTiming(
      hoverExitDelay: hoverExitDelay ?? this.hoverExitDelay,
      tooltipWait: tooltipWait ?? this.tooltipWait,
      tooltipShow: tooltipShow ?? this.tooltipShow,
      longPressDelay: longPressDelay ?? this.longPressDelay,
      typeAheadReset: typeAheadReset ?? this.typeAheadReset,
    );
  }

  // Waits do not blend between themes; the target's wait applies at once.
  @override
  TypewriterTiming lerp(TypewriterTiming? other, double t) {
    return other ?? this;
  }
}
