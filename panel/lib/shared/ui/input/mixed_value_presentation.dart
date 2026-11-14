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
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        toggled: false,
        mixed: true,
        enabled: enabled,
        // Space or Enter presses the row and turns it on once let go, as a
        // button acts.
        child: KeyPress(
          enabled: enabled,
          child: FocusableActionDetector(
            enabled: enabled,
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => onPressed?.call(),
              ),
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space3,
                  vertical: context.spacing.space2,
                ),
                child: Row(
                  spacing: context.spacing.space3,
                  children: [
                    if (leading) track,
                    Expanded(child: title),
                    if (!leading) track,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
    canvas
      ..drawRRect(bounds, Paint()..color = track)
      ..save()
      ..clipRRect(bounds);
    final stripes = Paint()
      ..color = stripe
      ..strokeWidth = size.height / 6;
    for (var x = -size.height; x < size.width; x += size.height / 3) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripes,
      );
    }
    canvas
      ..restore()
      ..drawCircle(
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
