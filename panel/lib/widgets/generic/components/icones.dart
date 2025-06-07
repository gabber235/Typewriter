import "package:flutter/material.dart";
import "package:iconify_flutter/iconify_flutter.dart";

class Icones extends StatelessWidget {
  const Icones(
    this.icon, {
    this.color,
    this.size,
    super.key,
  });

  final String icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color;
    final size = this.size ?? IconTheme.of(context).size;
    return Iconify(icon, color: color, size: size);
  }
}
