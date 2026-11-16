import "package:typewriter_panel/typewriter_panel.dart";

/// The app bar chip of the current mode, moving between [ModeLook]s.
///
/// The label types from one mode name to the next and the icon pops in; the
/// fill changes colour and strength between a tenth and three fifths of the
/// move, so it follows the label instead of jumping. The chip keeps one line
/// of height while the label is empty.
class ModeChip extends HookWidget {
  const ModeChip({required this.look, super.key});

  final ModeLook look;

  @override
  Widget build(BuildContext context) {
    final fill = look.soft
        ? look.tone.withValues(alpha: context.isDarkMode ? .16 : .14)
        : look.tone;
    final move = motionTimeline(context, MotionToken.panelIn);
    final controller = useAnimationController(duration: move.duration);
    final from = useRef(fill);
    final to = useRef(fill);
    useEffect(() {
      if (to.value == fill) return null;
      // A change mid move starts from the colour on screen.
      from.value = Color.lerp(
        from.value,
        to.value,
        move.curve.transform(controller.value).clamp(0, 1),
      )!;
      to.value = fill;
      if (move.isInstant) {
        controller.value = 1;
      } else {
        controller.forward(from: 0);
      }
      return null;
    }, [fill]);
    final progress = useAnimation(
      CurvedAnimation(parent: controller, curve: move.curve),
    );
    // The spring overshoots; a colour stops at the new fill.
    final shown = Color.lerp(from.value, to.value, progress.clamp(0, 1))!;
    // The ink reads on the fill the chip settles on; mid blend no tone of a
    // strong colour reads on every shade it passes.
    final ink = look.soft
        ? context.colors.textOf(
            look.tone,
            over: Color.alphaBlend(fill, context.colors.surface),
          )
        : fill.contrastingForeground;
    final style = context.theme.textTheme.labelMedium!.copyWith(color: ink);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: shown,
        borderRadius: context.shapes.smallBorderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space2,
          vertical: context.spacing.space1,
        ),
        child: IconTheme(
          data: IconThemeData(color: ink, size: 14),
          child: DefaultTextStyle(
            style: style,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElasticSwitcher(
                  child: switch (look.icon) {
                    final icon? => Padding(
                      key: ValueKey(icon),
                      padding: EdgeInsets.only(right: context.spacing.space1),
                      child: Icon(icon),
                    ),
                    null => const SizedBox.shrink(key: ValueKey("none")),
                  },
                ),
                // An invisible capital holds one line of height while the
                // label types through empty.
                Stack(
                  children: [
                    const Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Text("M"),
                    ),
                    MotionLabel(look.label.toUpperCase(), style: style),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
