import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:iconify_flutter_plus/icons/ph.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class Admonition extends StatelessWidget {
  const Admonition({
    required this.color,
    required this.icon,
    required this.child,
    this.onTap,
    super.key,
  });

  const Admonition.info({
    required this.child,
    this.onTap,
    super.key,
  })  : color = Colors.blue,
        icon = MaterialSymbols.info_rounded;

  const Admonition.warning({
    required this.child,
    this.onTap,
    super.key,
  })  : color = Colors.orange,
        icon = Ph.warning_fill;

  const Admonition.danger({
    required this.child,
    this.onTap,
    super.key,
  })  : color = Colors.red,
        icon = Ph.warning_octagon_fill;

  final Color color;
  final String icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: [
              Icones(
                icon,
                color: color,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: color,
                    fontVariations: const [FontVariation.width(1.2)],
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
