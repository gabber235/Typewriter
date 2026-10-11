import "package:typewriter_panel/typewriter_panel.dart";

final _iconRegex = RegExp(r"^([a-z0-9\-]+):([a-z0-9\-]+)$");
final _svgCache = ScalableImageCache(size: 100);

const _iconifyHosts = [
  "api.iconify.design",
  "api.simplesvg.com",
  "api.unisvg.com",
];

/// Renders an icon value from Iconify or sanitized inline SVG data.
///
/// Invalid values and failed remote loads render a broken image icon. Iconify
/// values are fetched from the public Iconify SVG endpoint and cached by the
/// SVG renderer.
class Icones extends StatelessWidget {
  /// Creates an icon from a string icon name or inline SVG value.
  const Icones(this.icon, {this.color, this.size, super.key})
    : iconValue = null;

  /// Creates an icon from the shared typed icon value.
  const Icones.value(IconValue value, {this.color, this.size, super.key})
    : iconValue = value,
      icon = null;

  final IconValue? iconValue;

  /// String icon name or inline SVG input used by the default constructor.
  final String? icon;

  /// Color applied to the rendered icon, or the ambient icon color when null.
  final Color? color;

  /// Rendered icon size, or the ambient icon size when null.
  final double? size;

  IconValue get _value => iconValue ?? IconValue.from(icon!);

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color;
    final size = this.size ?? IconTheme.of(context).size;

    final source = switch (_value) {
      IconifyIconValue(:final value) when value.isValidIconifyValue =>
        _IconifySource(value),
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
      currentColor: color,
      onError: (context) => _brokenImage(color, size),
    );

    return SizedBox(width: size, height: size, child: image);
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

final class _IconifySource extends ScalableImageSource {
  _IconifySource(this.value);

  final String value;

  @override
  Future<ScalableImage> createSI() => loadIconifySvg(value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _IconifySource && other.value == value;
}

/// Loads a valid Iconify SVG, using the public backup hosts on bad responses.
///
/// The HTTP source in the SVG widget parses error bodies as SVG. Validate the
/// response here so a failing host can be retried and its failure is visible.
Future<ScalableImage> loadIconifySvg(
  String value, {
  Client? client,
  List<String> hosts = _iconifyHosts,
}) async {
  final match = _iconRegex.firstMatch(value);
  if (match == null) {
    throw ArgumentError.value(value, "value", "Invalid Iconify name");
  }
  final ownedClient = client == null;
  final connection = client ?? Client();
  final failures = <String>[];
  try {
    for (final host in hosts) {
      try {
        final response = await connection.get(
          Uri.https(host, "${match.group(1)}/${match.group(2)}.svg"),
          headers: const {"Accept": "image/svg+xml"},
        );
        if (response.statusCode != 200) {
          failures.add("$host: HTTP ${response.statusCode}");
          continue;
        }
        final body = response.body.trimLeft();
        if (!body.startsWith("<svg")) {
          final contentType = response.headers["content-type"] ?? "unknown";
          failures.add(
            "$host: response is not SVG (content type $contentType)",
          );
          continue;
        }
        return ScalableImage.fromSvgString(body, warnF: _reportSvgWarning);
      } on Object catch (error) {
        failures.add("$host: $error");
      }
    }
  } finally {
    if (ownedClient) connection.close();
  }
  throw StateError(
    "Iconify SVG '$value' could not be loaded (${failures.join('; ')})",
  );
}

void _reportSvgWarning(String warning) {
  if (warning.toLowerCase().contains("preserveaspectratio")) return;
  debugPrint(warning);
}
