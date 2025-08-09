import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:mocktail/mocktail.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/main.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/components/selectable.stories.dart";

import "main.directories.g.dart";

void main() {
  Animate.restartOnHotReload = true;

  registerFallbackValue(ThemeMode.system);
  registerFallbackValue(
    TestSelectableIdentifier(
      id: "",
      dataBlueprint: ObjectBlueprint(fields: {}),
    ),
  );

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
      lightTheme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      appBuilder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: GlobalCustomScrollBehavior(),
          shortcuts: TypewriterPanel.typewriterShortcuts,
          home: Material(child: child),
        );
      },
      directories: directories,
    );
  }
}
