import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Three [PanelRow]s: hover and press the rows that act, Selected fills the
/// middle one, Dense packs them as a menu does, and a long title wraps.
/// Without Pressable the rows are plain text and never rise.
@widgetbook.UseCase(name: "Default", type: PanelRow)
Widget panelRowUseCase(BuildContext context) {
  final pressable = context.knobs.boolean(
    label: "Pressable",
    initialValue: true,
  );
  final selected = context.knobs.boolean(label: "Selected");
  final dense = context.knobs.boolean(label: "Dense");
  final width = context.knobs.width(const {"Wide": 420, "Narrow": 240});
  final onPressed = pressable ? () {} : null;
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelRow(
              leading: const Icon(Icons.person_outline),
              title: const Text("Ada"),
              subtitle: const Text("Owner"),
              dense: dense,
              onPressed: onPressed,
            ),
            PanelRow(
              leading: const Icon(Icons.person_outline),
              title: const Text("Grace"),
              subtitle: const Text("Editor"),
              trailing: const Icon(Icons.chevron_right),
              selected: selected,
              dense: dense,
              onPressed: onPressed,
            ),
            PanelRow(
              leading: const Icon(Icons.key_outlined),
              title: const Text(
                "Spring festival join code for the whole building team",
              ),
              dense: dense,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    ),
  );
}
