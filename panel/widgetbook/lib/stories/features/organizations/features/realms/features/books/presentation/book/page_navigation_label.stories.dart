import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Page navigation", type: PageNavigationLabel)
Widget pageNavigationLabelStory(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Sidebar width",
    initialValue: 200,
    min: 120,
    max: 300,
  );
  final count = context.knobs.int.slider(
    label: "Pages",
    initialValue: 200,
    min: 1,
    max: 500,
  );
  final issues = context.knobs.boolean(
    label: "Show issues",
    initialValue: true,
  );
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: width,
        child: ListView.builder(
          itemCount: count,
          itemBuilder: (context, index) => Surface(
            color: index == 0
                ? context.colors.selectionContainer
                : Colors.transparent,
            foreground: index == 0
                ? context.colors.onSelectionContainer
                : context.colors.contentSecondary,
            child: PageNavigationLabel(
              name: "Chapter ${index + 1}: Harbor arrival",
              issues: issues && index % 5 == 0
                  ? const [
                      ResourceIssue(
                        current: true,
                        diagnostic: PortablePresentationDiagnostic(
                          code: "unfinished_value",
                          message: "A required value is unfinished.",
                          severity: skir.DiagnosticSeverity.error,
                        ),
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
      ),
    ),
  );
}
