import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:iconify_flutter_plus/icons/ph.dart";
import "package:typewriter_panel/typewriter_panel.dart";

enum _AdmonitionKind { custom, info, warning, danger }

class Admonition extends StatelessWidget {
  const Admonition({
    required Color color,
    required this.icon,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 500),
    this.onTap,
    super.key,
  }) : _color = color,
       _kind = _AdmonitionKind.custom;

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
    final theme = Theme.of(context);
    final color =
        _color ??
        switch (_kind) {
          _AdmonitionKind.info => context.colors.info,
          _AdmonitionKind.warning => context.colors.warning,
          _AdmonitionKind.danger => context.colors.danger,
          _AdmonitionKind.custom => throw StateError("Missing custom color"),
        };
    final surfaceColor = Surface.colorOf(context);
    final backgroundColor = Color.alphaBlend(
      color.withValues(alpha: 0.1),
      surfaceColor,
    );
    return Surface(
      color: backgroundColor,
      child: Material(
        animationDuration: 500.ms,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color, width: 1),
          borderRadius: context.shapes.mediumBorderRadius,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: color),
                  child: icon,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: animationDuration,
                    style: theme.textTheme.titleSmall!.copyWith(color: color),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
