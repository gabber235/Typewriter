import "package:flutter/material.dart";
import "package:typewriter_panel/main.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "main.directories.g.dart";

void main() {
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
          MacosViewports.macbookPro,
          WindowsViewports.desktop,
          LinuxViewports.desktop,
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
      ],
      directories: directories,
    );
  }
}
