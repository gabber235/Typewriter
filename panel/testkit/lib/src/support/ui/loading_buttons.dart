import "package:typewriter_panel/typewriter_panel.dart";

/// The two shapes of a [LoadingButton]: a label alone, or a label beside an
/// "Add" icon the spinner replaces.
enum LoadingButtonShape {
  label,
  icon;

  /// A [LoadingButton] of this shape showing [label] that runs [onPressed].
  Widget button({
    required String label,
    required FutureOr<void> Function()? onPressed,
    LoadingVariant variant = LoadingVariant.filled,
    LoadingButtonController? controller,
  }) => switch (this) {
    LoadingButtonShape.label => LoadingButton(
      variant: variant,
      controller: controller,
      onPressed: onPressed,
      child: Text(label),
    ),
    LoadingButtonShape.icon => LoadingButton.icon(
      variant: variant,
      controller: controller,
      onPressed: onPressed,
      icon: const Icon(Icons.add, semanticLabel: "Add"),
      label: Text(label),
    ),
  };
}

/// The three styles of a [LoadingIconButton].
enum LoadingIconButtonStyle {
  standard,
  filled,
  outlined;

  /// A [LoadingIconButton] of this style showing [icon] that runs
  /// [onPressed].
  Widget button({
    required Widget icon,
    required FutureOr<void> Function()? onPressed,
    LoadingButtonController? controller,
  }) => switch (this) {
    standard => LoadingIconButton(
      icon: icon,
      onPressed: onPressed,
      controller: controller,
    ),
    filled => LoadingIconButton.filled(
      icon: icon,
      onPressed: onPressed,
      controller: controller,
    ),
    outlined => LoadingIconButton.outlined(
      icon: icon,
      onPressed: onPressed,
      controller: controller,
    ),
  };
}
