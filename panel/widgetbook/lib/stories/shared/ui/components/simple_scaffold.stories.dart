import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [SimpleScaffold]: its header above a body that fills the rest, or the
/// body alone when there is no header.
@widgetbook.UseCase(name: "Default", type: SimpleScaffold)
Widget simpleScaffoldUseCase(BuildContext context) {
  final header = context.knobs.boolean(label: "Header", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => SizedBox(
          width: 420,
          height: 320,
          child: SimpleScaffold(
            appBar: header
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(48),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Services"),
                    ),
                  )
                : null,
            child: ColoredBox(
              color: context.colors.surfaceContainer,
              child: const Center(child: Text("Body")),
            ),
          ),
        ),
      ),
    ),
  );
}
