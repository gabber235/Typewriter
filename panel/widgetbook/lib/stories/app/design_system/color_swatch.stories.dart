import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

class ColorSwatchShowcase extends StatelessWidget {
  const ColorSwatchShowcase({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSwatch(buildTheme(Brightness.light).scaffoldBackgroundColor),
        _buildSwatch(buildTheme(Brightness.dark).scaffoldBackgroundColor),
      ],
    );
  }

  Widget _buildSwatch(Color backgroundColor) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: CircleAvatar(backgroundColor: color)),
    );
  }
}

@widgetbook.UseCase(
  name: "Default",
  type: ColorSwatchShowcase,
  path: "app/design_system",
)
Widget colorSwatchUseCase(BuildContext context) {
  return FakeApp(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Wrap(
        runSpacing: 4,
        children: [
          for (final color in safeColors)
            ColorSwatchShowcase(color: color, key: ValueKey(color)),
        ],
      ),
    ),
  );
}
