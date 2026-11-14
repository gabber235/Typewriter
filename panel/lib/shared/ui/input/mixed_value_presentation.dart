import "package:typewriter_panel/typewriter_panel.dart";

/// The word a control shows in place of a value while the selected items
/// hold different values.
const mixedValueLabel = "Mixed";

const mixedValueReplacementMessage =
    "Changing this replaces all selected values.";

extension MixedValueInputDecoration on InputDecoration {
  /// This decoration saying the selected items differ: [mixedValueLabel] in
  /// place of the placeholder, and what an edit does under the field.
  InputDecoration get forMixedValue => copyWith(
    hintText: mixedValueLabel,
    helperText: mixedValueReplacementMessage,
  );
}

class MixedValueMessage extends StatelessWidget {
  const MixedValueMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.spacing.space2,
        top: context.spacing.space1,
      ),
      child: Text(
        mixedValueReplacementMessage,
        style: Theme.of(context).inputDecorationTheme.helperStyle,
      ),
    );
  }
}

/// A switch row for a setting the selected items hold differently.
///
/// Its track is striped and its thumb rests in the middle, so it reads as
/// neither on nor off. A click, or Space or Enter once let go, calls
/// [onPressed], which turns the setting on for every item; without it the row is heard as unavailable
/// and takes no focus. [leading] puts the switch before [title].
class MixedSwitchTile extends StatelessWidget {
  const MixedSwitchTile({
    required this.title,
    this.onPressed,
    this.leading = false,
    this.semanticLabel,
    super.key,
  });

  final Widget title;
  final VoidCallback? onPressed;
  final bool leading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final track = _MixedSwitchTrack(enabled: enabled);
    return PressableRow(
      semantics: SemanticsProperties(
        label: semanticLabel,
        toggled: false,
        mixed: true,
        enabled: enabled,
      ),
      onPressed: onPressed,
      children: [
        if (leading) track,
        Expanded(child: title),
        if (!leading) track,
      ],
    );
  }
}

class _MixedSwitchTrack extends StatelessWidget {
  const _MixedSwitchTrack({required this.enabled});

  final bool enabled;

  static const Size _size = Size(40, 24);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      size: _size,
      painter: _MixedSwitchPainter(
        track: colors.contentSecondary.withValues(alpha: 0.16),
        stripe: (enabled ? colors.accent : colors.contentDisabled).withValues(
          alpha: 0.45,
        ),
        thumb: enabled ? colors.contentPrimary : colors.contentDisabled,
      ),
    );
  }
}

class _MixedSwitchPainter extends CustomPainter {
  const _MixedSwitchPainter({
    required this.track,
    required this.stripe,
    required this.thumb,
  });

  final Color track;
  final Color stripe;
  final Color thumb;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(bounds, Paint()..color = track);
    paintMixedStripes(canvas, bounds, stripe, pitch: size.height / 3);
    canvas.drawCircle(
      size.center(Offset.zero),
      size.height / 2 - 4,
      Paint()..color = thumb,
    );
  }

  @override
  bool shouldRepaint(_MixedSwitchPainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.stripe != stripe ||
      oldDelegate.thumb != thumb;
}

/// Paints the diagonal stripes that mark a value the selected items hold
/// differently inside [bounds], one band of [color] every [pitch] pixels.
void paintMixedStripes(
  Canvas canvas,
  RRect bounds,
  Color color, {
  required double pitch,
}) {
  final rect = bounds.outerRect;
  final stripes = Paint()
    ..color = color
    ..strokeWidth = pitch / 2;
  canvas
    ..save()
    ..clipRRect(bounds);
  for (var x = rect.left - rect.height; x < rect.right; x += pitch) {
    canvas.drawLine(
      Offset(x, rect.bottom),
      Offset(x + rect.height, rect.top),
      stripes,
    );
  }
  canvas.restore();
}

/// A slider for a number the selected items hold differently.
///
/// Its track is striped, it has no thumb, and it is heard as
/// [mixedValueLabel]. A click or a drag sets the value under the pointer
/// once let go, showing a thumb where it will land while the drag lasts. An
/// arrow key steps once from [start], the value the first selected item
/// holds, and activating it from assistive technology sets [start] itself.
/// Each calls [onChanged] with a value from [min] to [max], on one of
/// [divisions] steps when given; without [onChanged] the slider is heard as
/// unavailable and takes no focus.
class MixedSlider extends HookWidget {
  const MixedSlider({
    required this.min,
    required this.max,
    required this.start,
    this.divisions,
    this.onChanged,
    super.key,
  });

  final double min;
  final double max;
  final double start;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  static const double _height = 40;
  static const double _track = 6;

  /// The value at [fraction] of the track, on a step when there are
  /// [divisions].
  double _at(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    final steps = divisions;
    final snapped = steps == null ? clamped : (clamped * steps).round() / steps;
    return min + snapped * (max - min);
  }

  /// [start] moved one step in [direction], a division or a tenth of the
  /// range.
  double _stepped(int direction) {
    final step = (max - min) / (divisions ?? 10);
    return (start + direction * step).clamp(min, max);
  }

  static String _spoken(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    final dragged = useState<double?>(null);
    final thumb = useMotion(MotionToken.ink, dragged.value == null ? 0 : 1);
    void step(int direction) => onChanged?.call(_stepped(direction));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double fractionAt(Offset position) =>
            width <= 0 ? 0 : position.dx / width;
        return Semantics(
          slider: true,
          value: mixedValueLabel,
          increasedValue: _spoken(_stepped(1)),
          decreasedValue: _spoken(_stepped(-1)),
          enabled: enabled,
          onTap: enabled ? () => onChanged!(start) : null,
          onIncrease: enabled ? () => step(1) : null,
          onDecrease: enabled ? () => step(-1) : null,
          child: FocusableActionDetector(
            enabled: enabled,
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
              SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
              SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
              SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
            },
            actions: {
              _StepIntent: CallbackAction<_StepIntent>(
                onInvoke: (intent) => step(intent.direction),
              ),
            },
            child: GestureDetector(
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTapUp: enabled
                  ? (details) =>
                        onChanged!(_at(fractionAt(details.localPosition)))
                  : null,
              onHorizontalDragUpdate: enabled
                  ? (details) =>
                        dragged.value = fractionAt(details.localPosition)
                  : null,
              onHorizontalDragEnd: enabled
                  ? (_) {
                      final fraction = dragged.value;
                      dragged.value = null;
                      if (fraction != null) onChanged!(_at(fraction));
                    }
                  : null,
              onHorizontalDragCancel: () => dragged.value = null,
              child: CustomPaint(
                size: Size(width, _height),
                painter: _MixedSliderPainter(
                  track: colors.contentSecondary.withValues(alpha: 0.16),
                  stripe: (enabled ? colors.accent : colors.contentDisabled)
                      .withValues(alpha: 0.45),
                  thumb: colors.accent.withValues(
                    alpha: thumb.value.clamp(0.0, 1.0),
                  ),
                  thumbAt: dragged.value?.clamp(0.0, 1.0),
                  trackHeight: _track,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StepIntent extends Intent {
  const _StepIntent(this.direction);

  final int direction;
}

class _MixedSliderPainter extends CustomPainter {
  const _MixedSliderPainter({
    required this.track,
    required this.stripe,
    required this.thumb,
    required this.thumbAt,
    required this.trackHeight,
  });

  final Color track;
  final Color stripe;
  final Color thumb;
  final double? thumbAt;
  final double trackHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width,
        height: trackHeight,
      ),
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(bounds, Paint()..color = track);
    paintMixedStripes(canvas, bounds, stripe, pitch: trackHeight);
    if (thumbAt case final at?) {
      canvas.drawCircle(
        Offset(at * size.width, size.height / 2),
        trackHeight * 1.5,
        Paint()..color = thumb,
      );
    }
  }

  @override
  bool shouldRepaint(_MixedSliderPainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.stripe != stripe ||
      oldDelegate.thumb != thumb ||
      oldDelegate.thumbAt != thumbAt ||
      oldDelegate.trackHeight != trackHeight;
}
