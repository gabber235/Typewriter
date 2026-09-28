import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Responsive slots", type: AdaptiveLeadingLayout)
Widget adaptiveLeadingLayoutUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 280,
    min: 72,
    max: 360,
  );
  final gap = context.knobs.double.slider(
    label: "Gap",
    initialValue: 8,
    min: 0,
    max: 24,
  );

  return FakeApp(
    child: Center(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: SizedBox(
          width: width,
          height: 64,
          child: AdaptiveLeadingLayout(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            compactPadding: const EdgeInsets.all(8),
            gap: gap,
            leading: const Icon(Icons.book_outlined),
            center: const Text(
              "A long presentation title",
              overflow: TextOverflow.ellipsis,
            ),
            suffix: IconButton(
              tooltip: "Open",
              onPressed: () {},
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
    ),
  );
}
