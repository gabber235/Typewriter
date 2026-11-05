import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The [EmptyState] of a list with nothing in it yet, with or without an
/// icon and action, in a wide or narrow space.
@widgetbook.UseCase(name: "Default", type: EmptyState)
Widget emptyStateUseCase(BuildContext context) {
  final icon = context.knobs.boolean(label: "Icon", initialValue: true);
  final action = context.knobs.boolean(label: "Action");
  final narrow = context.knobs.boolean(label: "Narrow");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: narrow ? 260 : 560,
        child: EmptyState(
          title: "No services connected",
          description:
              "Connect a Paper server with a registration token to host "
              "Realms.",
          icon: icon ? MaterialSymbols.dns : null,
          buttonText: action ? "Connect service" : null,
          onPressed: action ? () {} : null,
        ),
      ),
    ),
  );
}
