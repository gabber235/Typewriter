import "package:flutter/material.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/grid_selectable_card.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: GridSelectableCard)
Widget gridSelectableCardDefaultUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: "Title",
    initialValue: "Example Item",
  );
  final showBadge = context.knobs.boolean(
    label: "Show Badge",
    initialValue: true,
  );
  final badgeLabel = context.knobs.string(
    label: "Badge Label",
    initialValue: "ENGINE",
  );
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 200,
    min: 140,
    max: 280,
  );
  final height = context.knobs.double.slider(
    label: "Height",
    initialValue: 160,
    min: 120,
    max: 220,
  );

  final baseColor = context.knobs.color(
    label: "Base Color",
    initialValue: Colors.blue,
  );

  return FakeApp(
    child: Center(
      child: Selector(
        selectableId: TestSelectableIdentifier(
          id: "grid_selectable_card",
          color: baseColor,
        ),
        builder: (isSelected, isFocused, isHovered) {
          return GridSelectableCard(
            title: title,
            baseColor: baseColor,
            isSelected: isSelected,
            isFocused: isFocused,
            isHovered: isHovered,
            width: width,
            height: height,
            badgeLabel: showBadge ? badgeLabel : null,
          );
        },
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Grid Sample", type: GridSelectableCard)
Widget gridSelectableCardGridUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 200,
    min: 140,
    max: 280,
  );
  final height = context.knobs.double.slider(
    label: "Height",
    initialValue: 160,
    min: 120,
    max: 220,
  );

  return FakeApp(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(safeColors.length, (i) {
            final color = safeColors[i];
            return Selector(
              selectableId: TestSelectableIdentifier(
                id: "item_$i",
                color: color,
              ),
              builder: (isSelected, isFocused, isHovered) {
                return GridSelectableCard(
                  title: "Item ${i + 1}",
                  baseColor: color,
                  isSelected: isSelected,
                  isFocused: isFocused,
                  isHovered: isHovered,
                  width: width,
                  height: height,
                  badgeLabel: i.isEven ? "EXTENSION" : "ENGINE",
                );
              },
            );
          }),
        ),
      ),
    ),
  );
}
