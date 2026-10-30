import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _long =
    "Search matches titles, tags and page names. Combine terms with a space "
    "to narrow results, prefix a term with a minus to exclude it, and quote "
    "a phrase to match it exactly. Results update as you type.";

/// [Admonition]s of every kind, with short and long content; a tappable one
/// reacts to the pointer.
@widgetbook.UseCase(name: "Default", type: Admonition)
Widget admonitionUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long content");
  final tappable = context.knobs.boolean(label: "Tappable");
  final onTap = tappable ? () {} : null;
  Widget text(String short) => Text(long ? _long : short);
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Admonition.info(
              onTap: onTap,
              child: text("Type to search the Realm."),
            ),
            Admonition.warning(
              onTap: onTap,
              child: text("This color is hard to read on light themes."),
            ),
            Admonition.danger(
              onTap: onTap,
              child: text("Deleting this tag removes it from 12 Books."),
            ),
            Admonition(
              color: Colors.teal,
              icon: const Icon(Icons.tips_and_updates),
              onTap: onTap,
              child: text("Press / to focus search from anywhere."),
            ),
          ],
        ),
      ),
    ),
  );
}
