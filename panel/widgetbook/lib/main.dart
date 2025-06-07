import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:mocktail/mocktail.dart";
import "package:typewriter_panel/main.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "main.directories.g.dart";

void main() {
  Animate.restartOnHotReload = true;

  registerFallbackValue(ThemeMode.system);

  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          IosViewports.iPad,
          AndroidViewports.samsungGalaxyNote20,
          AndroidViewports.largeTablet,
          LinuxViewports.desktop,
          ViewportData(
            name: "Ulta Wide Desktop",
            width: 3440,
            height: 1440,
            pixelRatio: 2,
            platform: TargetPlatform.windows,
          ),
        ]),
        InspectorAddon(),
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: "Dark", data: buildTheme(Brightness.dark)),
            WidgetbookTheme(name: "Light", data: buildTheme(Brightness.light)),
          ],
        ),
        BuilderAddon(
          name: "Responsive",
          builder: (context, child) => Responsive(child: child),
        ),
        AlignmentAddon(),
        ZoomAddon(),
        TimeDilationAddon(),
      ],
      directories: directories,
    );
  }
}
