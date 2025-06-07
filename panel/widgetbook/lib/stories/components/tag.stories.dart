import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/generic/components/tag.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/logic/tag.mock.dart";

@widgetbook.UseCase(name: "Default", type: TagWidget)
Widget tagUseCase(BuildContext context) {
  final tag = ensureRandomTag(1.9, 0.5);
  return HookBuilder(
    builder: (context) {
      final isExpanded = useState(true);
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Expanded:"),
                Switch(
                  value: isExpanded.value,
                  onChanged: (value) => isExpanded.value = value,
                ),
              ],
            ),
            TagWidget(isExpanded: isExpanded.value, tag: tag),
          ],
        ),
      );
    },
  );
}
