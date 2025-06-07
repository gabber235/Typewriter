import "package:flutter/material.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

class ColorSwatchWidget extends StatelessWidget {
  const ColorSwatchWidget({required this.color, super.key});

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

@widgetbook.UseCase(name: "Default", type: ColorSwatchWidget)
Widget colorSwatchUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Wrap(
      runSpacing: 4,
      children: [
        for (final color in safeColors)
          ColorSwatchWidget(color: color, key: ValueKey(color)),
      ],
    ),
  );
}
