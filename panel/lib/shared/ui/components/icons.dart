import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:http/http.dart" as http;
import "package:typewriter_panel/shared/editors/domain/values/icon_value.dart";

final _iconRegex = RegExp(r"^([a-z0-9\-]+):([a-z0-9\-]+)$");

class Icones extends StatefulWidget {
  const Icones(String icon, {this.color, this.size, super.key})
    : iconify = icon,
      icon = null;

  const Icones.value(IconValue value, {this.color, this.size, super.key})
    : icon = value,
      iconify = null;

  final IconValue? icon;
  final String? iconify;
  final Color? color;
  final double? size;

  @override
  State<Icones> createState() => _IconesState();
}

class _IconesState extends State<Icones> {
  Future<String?>? _iconifySource;

  IconValue get _value => widget.icon ?? IconValue.iconify(widget.iconify!);

  @override
  void initState() {
    super.initState();
    _loadIconifySource();
  }

  @override
  void didUpdateWidget(covariant Icones oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon == widget.icon && oldWidget.iconify == widget.iconify) {
      return;
    }
    _loadIconifySource();
  }

  void _loadIconifySource() {
    _iconifySource = switch (_value) {
      IconifyIconValue(:final value) => value._loadSvg(),
      SvgIconValue() => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? IconTheme.of(context).color;
    final size = widget.size ?? IconTheme.of(context).size;

    return switch (_value) {
      IconifyIconValue() => FutureBuilder(
        future: _iconifySource,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot<String>(hasData: true, :final data) => _svg(
            data!,
            color,
            size,
          ),
          AsyncSnapshot<String?>(connectionState: ConnectionState.done) =>
            _brokenImage(color, size),
          _ => SizedBox(width: size, height: size),
        },
      ),
      SvgIconValue(:final source) when source.isSanitizedSvg => _svg(
        source,
        color,
        size,
      ),
      SvgIconValue() => _brokenImage(color, size),
    };
  }

  Widget _svg(String source, Color? color, double? size) => SvgPicture.string(
    source,
    colorFilter: color != null
        ? ColorFilter.mode(color, BlendMode.srcIn)
        : null,
    width: size,
    height: size,
    alignment: Alignment.center,
    errorBuilder: (context, error, stackTrace) => _brokenImage(color, size),
  );

  Widget _brokenImage(Color? color, double? size) =>
      Icon(Icons.broken_image, color: color, size: size);
}

extension on String {
  Future<String?> _loadSvg() async {
    if (!_iconRegex.hasMatch(this)) return null;
    final match = _iconRegex.firstMatch(this)!;
    final prefix = match.group(1)!;
    final name = match.group(2)!;
    final uri = Uri.parse("https://api.iconify.design/$prefix/$name.svg");
    try {
      final response = await http
          .get(uri, headers: const {"Accept": "image/svg+xml"})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200 || !response.body.isSanitizedSvg) {
        return null;
      }
      return response.body;
    } on Object {
      return null;
    }
  }
}
