import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [PanelSheetRoute] opened by its button: it rises from the bottom edge,
/// and Escape, a click on the veil, or a drag down closes it.
@widgetbook.UseCase(name: "Rising sheet", type: PanelSheetRoute)
Widget panelSheetUseCase(BuildContext context) {
  return Story(
    context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
    at: PanelLocation.component(
      Builder(
        builder: (context) => Center(
          child: Button(
            label: "Open sheet",
            autofocus: true,
            onPressed: () => context.showPanelSheet<void>(
              (_) => const SizedBox(
                height: 300,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Drag me down, or press Escape."),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A [SheetCard] floating inside a sheet, as the activity list shows on a
/// phone.
@widgetbook.UseCase(name: "Card in a sheet", type: SheetCard)
Widget sheetCardUseCase(BuildContext context) {
  return Story(
    const [compact],
    at: PanelLocation.component(
      Builder(
        builder: (context) => Center(
          child: Button(
            label: "Show activity",
            autofocus: true,
            onPressed: () => context.showPanelSheet<void>(
              (context) => const SheetCard(
                maxHeight: 320,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Old Notes was published."),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
