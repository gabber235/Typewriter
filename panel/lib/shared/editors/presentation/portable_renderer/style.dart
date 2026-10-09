part of "../portable_presentation_renderer.dart";

EdgeInsets _presentationInsets(skir.PresentationInsets? insets) =>
    switch (insets) {
      skir.PresentationInsets_allWrapper(:final value) => EdgeInsets.all(value),
      skir.PresentationInsets_symmetricWrapper(:final value) =>
        EdgeInsets.symmetric(
          horizontal: value.horizontal,
          vertical: value.vertical,
        ),
      skir.PresentationInsets_onlyWrapper(:final value) => EdgeInsets.fromLTRB(
        value.left,
        value.top,
        value.right,
        value.bottom,
      ),
      _ => EdgeInsets.zero,
    };

Color? _paragraphToneColor(
  BuildContext context,
  skir.PresentationTextTone tone,
) => switch (tone.kind) {
  skir.PresentationTextTone_kind.secondaryConst =>
    Surface.secondaryForegroundOf(context),
  _ => null,
};

Color _statusColor(BuildContext context, skir.StatusTone tone) =>
    switch (tone.kind) {
      skir.StatusTone_kind.successConst => context.colors.success,
      skir.StatusTone_kind.activeConst ||
      skir.StatusTone_kind.onlineConst => context.colors.online,
      skir.StatusTone_kind.warningConst ||
      skir.StatusTone_kind.pausedConst => context.colors.warning,
      skir.StatusTone_kind.dangerConst => context.colors.danger,
      skir.StatusTone_kind.inactiveConst ||
      skir.StatusTone_kind.offlineConst => context.colors.offline,
      skir.StatusTone_kind.informationConst ||
      skir.StatusTone_kind.pendingConst ||
      skir.StatusTone_kind.inProgressConst => context.colors.info,
      _ => context.colors.contentSecondary,
    };

IconData _statusIcon(skir.StatusTone tone) => switch (tone.kind) {
  skir.StatusTone_kind.neutralConst => Icons.circle_outlined,
  skir.StatusTone_kind.informationConst => Icons.info_outline,
  skir.StatusTone_kind.successConst => Icons.check_circle_outline,
  skir.StatusTone_kind.warningConst => Icons.warning_amber_rounded,
  skir.StatusTone_kind.dangerConst => Icons.error_outline,
  skir.StatusTone_kind.activeConst => Icons.play_circle_outline,
  skir.StatusTone_kind.inactiveConst => Icons.stop_circle_outlined,
  skir.StatusTone_kind.onlineConst => Icons.cloud_done_outlined,
  skir.StatusTone_kind.offlineConst => Icons.cloud_off_outlined,
  skir.StatusTone_kind.pendingConst => Icons.schedule_outlined,
  skir.StatusTone_kind.inProgressConst => Icons.sync,
  skir.StatusTone_kind.pausedConst => Icons.pause_circle_outline,
  _ => Icons.help_outline,
};

IconData _materialIcon(String name) => switch (name) {
  "add" => Icons.add,
  "delete" => Icons.delete,
  "edit" => Icons.edit,
  "save" => Icons.save,
  "search" => Icons.search,
  "more_vert" => Icons.more_vert,
  "auto_awesome" => Icons.auto_awesome,
  _ => Icons.help_outline,
};

BorderRadius? _radius(
  BuildContext context,
  skir.PresentationRadius radius,
  PortablePresentationScope scope,
) => switch (radius.kind) {
  skir.PresentationRadius_kind.noneConst => BorderRadius.zero,
  skir.PresentationRadius_kind.smallConst => context.shapes.smallBorderRadius,
  skir.PresentationRadius_kind.mediumConst => context.shapes.mediumBorderRadius,
  skir.PresentationRadius_kind.largeConst => context.shapes.largeBorderRadius,
  skir.PresentationRadius_kind.customWrapper => BorderRadius.circular(
    _number(scope, (radius as skir.PresentationRadius_customWrapper).value) ??
        0,
  ),
  _ => null,
};

BorderSide _borderSide(
  BuildContext context,
  skir.PresentationBorderSide side,
  PortablePresentationScope scope, {
  SurfaceAppearance? appearance,
}) => BorderSide(
  color:
      _color(context, scope, side.color, appearance: appearance) ??
      context.colors.borderSubtle,
  width: side.width,
);

BoxBorder? _border(
  BuildContext context,
  skir.PresentationBorder? border,
  PortablePresentationScope scope, {
  SurfaceAppearance? appearance,
}) => switch (border) {
  skir.PresentationBorder_allWrapper(:final value) => Border.fromBorderSide(
    _borderSide(context, value, scope, appearance: appearance),
  ),
  skir.PresentationBorder_sidesWrapper(:final value) => BorderDirectional(
    top: value.top == null
        ? BorderSide.none
        : _borderSide(context, value.top!, scope, appearance: appearance),
    start: value.start == null
        ? BorderSide.none
        : _borderSide(context, value.start!, scope, appearance: appearance),
    end: value.end == null
        ? BorderSide.none
        : _borderSide(context, value.end!, scope, appearance: appearance),
    bottom: value.bottom == null
        ? BorderSide.none
        : _borderSide(context, value.bottom!, scope, appearance: appearance),
  ),
  _ => null,
};
