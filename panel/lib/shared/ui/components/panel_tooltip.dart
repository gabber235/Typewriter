import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's one tooltip, on [RawTooltip]: it waits `tooltipWait`,
/// arrives with panelIn and leaves with panelOut. A sentence on the raised
/// surface, no Material.
class PanelTooltip extends StatelessWidget {
  const PanelTooltip({
    required this.message,
    required this.child,
    this.tooltipKey,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.excludeFromSemantics = false,
    this.wait,
    this.showFor,
    this.preferBelow,
    this.decoration,
    this.textStyle,
    this.padding,
    super.key,
  });

  final String message;
  final Widget child;

  /// Reaches the tooltip to show it on focus or by hand.
  final GlobalKey<RawTooltipState>? tooltipKey;
  final TooltipTriggerMode triggerMode;
  final bool excludeFromSemantics;

  /// A wait a service declared in place of `tooltipWait`.
  final Duration? wait;

  /// How long a touch shown tooltip stays, when a service declared it.
  final Duration? showFor;

  /// Whether the tooltip goes below its target; above by default.
  final bool? preferBelow;

  /// A service declared look over the panel's.
  final BoxDecoration? decoration;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final start = context.motion.spec(MotionToken.panelIn).landing.originScale;
    final below = preferBelow ?? false;
    final offset = context.spacing.space8;
    return RawTooltip(
      key: tooltipKey,
      semanticsTooltip: excludeFromSemantics ? null : message,
      hoverDelay: wait ?? context.timing.tooltipWait,
      touchDelay: showFor ?? context.timing.tooltipShow,
      triggerMode: triggerMode,
      // Away from the target by space8, as the tooltip theme placed it.
      positionDelegate: (placement) => positionDependentBox(
        size: placement.overlaySize,
        childSize: placement.tooltipSize,
        target: placement.target,
        verticalOffset: offset,
        preferBelow: below,
      ),
      animationStyle: motionTimeline(
        context,
        MotionToken.panelIn,
      ).styleWith(motionTimeline(context, MotionToken.panelOut)),
      tooltipBuilder: (context, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: lerpDouble(start, 1, animation.value),
            alignment: below ? Alignment.topCenter : Alignment.bottomCenter,
            child: child,
          ),
        ),
        child: DecoratedBox(
          decoration:
              BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: context.shapes.mediumBorderRadius,
                boxShadow: context.menuShadow,
              ).copyWith(
                color: decoration?.color,
                border: decoration?.border,
                borderRadius: decoration?.borderRadius,
              ),
          child: Padding(
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: context.spacing.space2,
                  vertical: context.spacing.space1,
                ),
            child: Text(
              message,
              style: context.text.sentence
                  .copyWith(color: context.colors.contentPrimary)
                  .merge(textStyle),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
