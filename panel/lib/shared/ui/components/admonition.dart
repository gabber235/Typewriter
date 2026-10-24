import "package:typewriter_panel/typewriter_panel.dart";

enum _AdmonitionKind { custom, info, warning, danger }

/// Presents an informational, warning, danger, or custom message surface.
///
/// The optional tap callback makes the whole surface interactive. It does not
/// own the action represented by the message, so callers remain responsible
/// for navigation, dismissal, or recovery.
class Admonition extends StatelessWidget {
  const Admonition({
    required Color this._color,
    required this.icon,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 500),
    this.onTap,
    super.key,
  }) : _kind = _AdmonitionKind.custom;

  const Admonition.info({
    required this.child,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 500),
    super.key,
  }) : _color = null,
       _kind = _AdmonitionKind.info,
       icon = const Icones(MaterialSymbols.info_rounded);

  const Admonition.warning({
    required this.child,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 500),
    super.key,
  }) : _color = null,
       _kind = _AdmonitionKind.warning,
       icon = const Icones(Ph.warning_fill);

  const Admonition.danger({
    required this.child,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 500),
    super.key,
  }) : _color = null,
       _kind = _AdmonitionKind.danger,
       icon = const Icones(Ph.warning_octagon_fill);

  final Color? _color;
  final _AdmonitionKind _kind;
  final Widget icon;
  final Widget child;
  final VoidCallback? onTap;

  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final color =
        _color ??
        switch (_kind) {
          _AdmonitionKind.info => context.colors.info,
          _AdmonitionKind.warning => context.colors.warning,
          _AdmonitionKind.danger => context.colors.danger,
          _AdmonitionKind.custom => throw StateError("Missing custom color"),
        };
    final backgroundColor = color.withValues(alpha: color.a * 0.1);
    return SurfaceContainer(
      duration: animationDuration,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: color, width: 1),
        borderRadius: context.shapes.mediumBorderRadius,
      ),
      foreground: color,
      child: Builder(
        builder: (context) => Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: context.shapes.mediumBorderRadius,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  icon,
                  SizedBox(width: context.spacing.space3),
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.titleSmall,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
