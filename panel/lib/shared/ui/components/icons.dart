import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:iconify_flutter_plus/iconify_flutter_plus.dart";

final iconRegex = RegExp(r"^([a-z0-9\-]+):([a-z0-9\-]+)$");

class Icones extends StatelessWidget {
  const Icones(this.icon, {this.color, this.size, super.key});

  final String icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color;
    final size = this.size ?? IconTheme.of(context).size;

    if (iconRegex.hasMatch(icon)) {
      final match = iconRegex.firstMatch(icon)!;
      final prefix = match.group(1)!;
      final name = match.group(2)!;
      final uri = Uri.parse("https://api.iconify.design/$prefix/$name.svg");
      return SvgPicture.network(
        uri.toString(),
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
        width: size,
        height: size,
        alignment: Alignment.center,
      );
    }

    return Iconify(icon, color: color, size: size);
  }
}
