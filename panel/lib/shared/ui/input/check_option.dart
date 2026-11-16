import "package:typewriter_panel/typewriter_panel.dart";

/// One choice of a set of known choices, checked while it is held.
///
/// [value] is true when every selected item holds the choice, false when
/// none does, and null when only some do: then the box is striped and
/// [detail] says how many, such as "1 of 2". One item and many items show
/// the same row. A click, or Space or Enter once let go, calls [onPressed];
/// without it the option is heard as unavailable and takes no focus.
class CheckOption extends HookWidget {
  const CheckOption({
    required this.label,
    required this.value,
    this.detail,
    this.onPressed,
    super.key,
  });

  final String label;
  final bool? value;
  final String? detail;
  final VoidCallback? onPressed;

  static const double _box = 18;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    final checked = useMotion(MotionToken.ink, value == true ? 1 : 0);
    final some = useMotion(MotionToken.ink, value == null ? 1 : 0);
    final t = checked.value.clamp(0.0, 1.0);
    final accent = enabled ? colors.accent : colors.contentDisabled;
    final fill = Color.lerp(
      colors.contentSecondary.withValues(alpha: 0.16),
      accent,
      t,
    )!;
    return PressableRow(
      semantics: SemanticsProperties(
        checked: value ?? false,
        mixed: value == null,
        enabled: enabled,
      ),
      onPressed: onPressed,
      children: [
        CustomPaint(
          size: const Size.square(_box),
          painter: _CheckBoxPainter(
            fill: fill,
            stripe: accent.withValues(alpha: 0.6 * some.value.clamp(0.0, 1.0)),
            radius: context.shapes.small,
          ),
          child: SizedBox.square(
            dimension: _box,
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.6 + 0.4 * t,
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: fill.contrastingForeground,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        if (value == null && detail != null)
          Text(
            detail!,
            style: textTheme.bodySmall?.copyWith(
              color: colors.contentSecondary,
            ),
          ),
      ],
    );
  }
}

class _CheckBoxPainter extends CustomPainter {
  const _CheckBoxPainter({
    required this.fill,
    required this.stripe,
    required this.radius,
  });

  final Color fill;
  final Color stripe;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(bounds, Paint()..color = fill);
    if (stripe.a > 0) {
      paintMixedStripes(canvas, bounds, stripe, pitch: size.height / 3);
    }
  }

  @override
  bool shouldRepaint(_CheckBoxPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.stripe != stripe ||
      oldDelegate.radius != radius;
}
