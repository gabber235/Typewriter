import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final _iconRegex = RegExp(r"^([a-z0-9\-]+):([a-z0-9\-]+)$");

class Icones extends StatelessWidget {
  const Icones(this.icon, {this.color, this.size, super.key})
    : iconValue = null;

  const Icones.value(IconValue value, {this.color, this.size, super.key})
    : iconValue = value,
      icon = null;

  final IconValue? iconValue;
  final String? icon;
  final Color? color;
  final double? size;

  IconValue get _value => iconValue ?? IconValue.from(icon!);

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color;
    final size = this.size ?? IconTheme.of(context).size;

    final bytesLoader = switch (_value) {
      IconifyIconValue(:final value) => SvgNetworkLoader(
        value.iconifyUrl,
        headers: {"Accept": "image/svg+xml"},
      ),
      SvgIconValue(:final source) => SvgStringLoader(source),
    };

    return SvgPicture(
      bytesLoader,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      width: size,
      height: size,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) => _brokenImage(color, size),
    );
  }

  Widget _brokenImage(Color? color, double? size) =>
      Icon(Icons.broken_image, color: color, size: size);
}

extension on String {
  String get iconifyUrl {
    final match = _iconRegex.firstMatch(this)!;
    final prefix = match.group(1)!;
    final name = match.group(2)!;
    return "https://api.iconify.design/$prefix/$name.svg";
  }
}
