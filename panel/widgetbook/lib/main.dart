import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "main.directories.g.dart";

void main() {
  Animate.restartOnHotReload = true;
  debugTracePostFrameCallbacks = true;

  runApp(const TypewriterWidgetbook());
}

@widgetbook.App()
class TypewriterWidgetbook extends StatelessWidget {
  const TypewriterWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTheme = WidgetbookTheme(
      name: "Dark",
      data: buildTheme(Brightness.dark),
    );
    final lightTheme = WidgetbookTheme(
      name: "Light",
      data: buildTheme(Brightness.light),
    );

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
          themes: [darkTheme, lightTheme],
          initialTheme: SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? darkTheme : lightTheme,
        ),
        AlignmentAddon(),
        ZoomAddon(),
      ],
      lightTheme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      appBuilder: (context, child) {
        // Don't have the MaterialApp here.
        // We have it in the `FakeApp` so that it rerenders when we make changes to the theme.
        return child;
      },
      directories: directories,
    );
  }
}
