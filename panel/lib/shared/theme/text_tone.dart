import "package:typewriter_panel/typewriter_panel.dart";

// Written by cargo xtask generate.
part "text_tone.freezed.dart";

/// Lowest WCAG contrast any text colour may have against its background.
const minimumTextContrast = 4.5;

/// How far a light theme may turn a hue, in degrees, to gain chroma.
const _lightHueTurn = 10;

/// A colour in OKLCH. [hue] is in radians. Points may lie outside sRGB.
@freezed
abstract class Oklch with _$Oklch {
  const factory Oklch({
    required double lightness,
    required double chroma,
    required double hue,
  }) = _Oklch;
  const Oklch._();

  /// Linear sRGB channels; they fall outside 0..1 when out of gamut.
  (double, double, double) get _linearRgb {
    final labA = chroma * cos(hue);
    final labB = chroma * sin(hue);
    final l = pow(lightness + 0.3963377774 * labA + 0.2158037573 * labB, 3);
    final m = pow(lightness - 0.1055613458 * labA - 0.0638541728 * labB, 3);
    final s = pow(lightness - 0.0894841775 * labA - 1.2914855480 * labB, 3);
    return (
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.7076266914 * s,
    );
  }

  /// Whether sRGB can show this point.
  bool get inGamut {
    bool inside(double channel) => channel >= -1e-6 && channel <= 1 + 1e-6;
    final (r, g, b) = _linearRgb;
    return inside(r) && inside(g) && inside(b);
  }

  /// The same lightness and hue at the largest chroma sRGB can show.
  Oklch get mostVivid {
    var low = 0.0;
    var high = 0.4;
    for (var step = 0; step < 40; step++) {
      final middle = (low + high) / 2;
      if (copyWith(chroma: middle).inGamut) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return copyWith(chroma: low);
  }

  /// This point rounded to an opaque 8 bit sRGB colour, clamped into gamut.
  Color get srgb {
    final (r, g, b) = _linearRgb;
    int channel(double linear) => (linear.clamp(0.0, 1.0).gamma * 255).round();
    return Color.fromARGB(255, channel(r), channel(g), channel(b));
  }
}

extension on double {
  /// sRGB transfer: encoded channel to linear light.
  double get linear => this <= 0.04045
      ? this / 12.92
      : pow((this + 0.055) / 1.055, 2.4).toDouble();

  /// sRGB transfer: linear light to encoded channel.
  double get gamma =>
      this <= 0.0031308 ? 12.92 * this : 1.055 * pow(this, 1 / 2.4) - 0.055;

  double get cubeRoot =>
      this < 0 ? -pow(-this, 1 / 3).toDouble() : pow(this, 1 / 3).toDouble();
}

final _tones = <(int, Brightness, int), Color>{};

/// Contrast, OKLCH and readable text tones for a colour.
extension ColorTextTone on Color {
  /// WCAG 2 contrast ratio between this colour and [other].
  double contrastWith(Color other) {
    final a = computeLuminance();
    final b = other.computeLuminance();
    return (max(a, b) + 0.05) / (min(a, b) + 0.05);
  }

  /// This colour in OKLCH.
  Oklch get oklch {
    final red = r.linear;
    final green = g.linear;
    final blue = b.linear;
    final l = (0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue)
        .cubeRoot;
    final m = (0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue)
        .cubeRoot;
    final s = (0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue)
        .cubeRoot;
    final labA = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    final labB = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    return Oklch(
      lightness: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      chroma: sqrt(labA * labA + labB * labB),
      hue: atan2(labB, labA),
    );
  }

  /// This hue as text in a theme of [brightness].
  ///
  /// The result reads at 4.5:1 on every one of [backgrounds] and keeps the
  /// most chroma sRGB allows at that lightness. A dark theme keeps the hue; a
  /// light theme may turn it up to 10 degrees when that gives more chroma.
  /// Throws a [StateError] when no lightness passes, which only happens for
  /// mid grey backgrounds and fails the theme build in tests.
  Color textTone(Brightness brightness, List<Color> backgrounds) {
    final key = (
      toARGB32(),
      brightness,
      Object.hashAll(backgrounds.map((color) => color.toARGB32())),
    );
    return _tones[key] ??= _searchTextTone(brightness, backgrounds);
  }

  Color _searchTextTone(Brightness brightness, List<Color> backgrounds) {
    final light = brightness == Brightness.light;
    bool readable(Color tone) => backgrounds.every(
      (background) => tone.contrastWith(background) >= minimumTextContrast,
    );

    /// The first lightness, from the background's side, whose most vivid
    /// colour at [hue] is readable.
    Color? firstReadable(double hue) {
      for (var step = 0; step < 900; step++) {
        final lightness = light ? 1.0 - step / 1000 : 0.1 + step / 1000;
        final tone = Oklch(
          lightness: lightness,
          chroma: 0,
          hue: hue,
        ).mostVivid.srgb;
        if (readable(tone)) return tone;
      }
      return null;
    }

    final base = oklch.hue;
    final turns = light
        ? [
            for (
              var degrees = -_lightHueTurn;
              degrees <= _lightHueTurn;
              degrees += 2
            )
              degrees,
          ]
        : const [0];
    Color? best;
    var bestChroma = -1.0;
    for (final degrees in turns) {
      final tone = firstReadable(base + degrees * pi / 180);
      if (tone == null) continue;
      final chroma = tone.oklch.chroma;
      if (chroma > bestChroma) {
        best = tone;
        bestChroma = chroma;
      }
    }
    if (best == null) {
      throw StateError(
        "No text tone of $this reads at $minimumTextContrast:1 on $backgrounds",
      );
    }
    return best;
  }
}

/// Text tones for hues that are not one of the five named twins, such as
/// role colours, mode chips and admonitions.
extension TypewriterTextTones on TypewriterColors {
  /// Every surface text in this theme must read on.
  List<Color> get textSurfaces => [
    canvas,
    panel,
    surface,
    surfaceContainer,
    surfaceRaised,
    surfaceEmphasized,
  ];

  /// Whether this theme is light or dark, read from its canvas.
  Brightness get brightness => ThemeData.estimateBrightnessForColor(canvas);

  /// [hue] as text on this theme's surfaces, and on [over] when the text sits
  /// on a tint of its own hue.
  Color textOf(Color hue, {Color? over}) =>
      hue.textTone(brightness, [...textSurfaces, ?over]);
}
