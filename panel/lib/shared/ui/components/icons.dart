import "package:flutter/material.dart";
import "package:jovial_svg/jovial_svg.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final _iconRegex = RegExp(r"^([a-z0-9\-]+):([a-z0-9\-]+)$");
final _svgCache = ScalableImageCache(size: 100);

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

    final source = switch (_value) {
      IconifyIconValue(:final value) when value.isValidIconifyValue =>
        ScalableImageSource.fromSvgHttpUrl(
          Uri.parse(value.iconifyUrl),
          httpHeaders: {"Accept": "image/svg+xml"},
          warnF: _reportSvgWarning,
        ),
      SvgIconValue(:final source) when source.isSanitizedSvg =>
        _SvgStringSource(source),
      _ => null,
    };

    if (source == null) {
      return SizedBox(
        width: size,
        height: size,
        child: _brokenImage(color, size),
      );
    }

    final image = ScalableImageWidget.fromSISource(
      si: source,
      cache: _svgCache,
      isComplex: true,
      onError: (context) => _brokenImage(color, size),
    );

    return SizedBox(
      width: size,
      height: size,
      child: color == null
          ? image
          : ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: image,
            ),
    );
  }

  Widget _brokenImage(Color? color, double? size) =>
      Icon(Icons.broken_image, color: color, size: size);
}

final class _SvgStringSource extends ScalableImageSource {
  _SvgStringSource(this.source);

  final String source;

  @override
  Future<ScalableImage> createSI() => Future(
    () => ScalableImage.fromSvgString(source, warnF: _reportSvgWarning),
  );

  @override
  int get hashCode => source.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _SvgStringSource && other.source == source;
}

void _reportSvgWarning(String warning) {
  if (warning.toLowerCase().contains("preserveaspectratio")) return;
  debugPrint(warning);
}

extension on String {
  String get iconifyUrl {
    final match = _iconRegex.firstMatch(this)!;
    final prefix = match.group(1)!;
    final name = match.group(2)!;
    return "https://api.iconify.design/$prefix/$name.svg";
  }
}
