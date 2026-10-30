import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";

/// What a type picker returned once it closed, null until then or when it
/// was cancelled.
final class PickedType {
  /// The chosen selection.
  skir.TypeSelection? selection;
}

/// The text field of the open type search.
final typeSearchField = find.descendant(
  of: find.byType(QueryBar),
  matching: find.byType(EditableText),
);

/// Choosing types the way an author does.
extension TypeChoosers on WidgetTester {
  /// Shows a button [label] that opens the picker of concrete resource types
  /// descending from [expected] in [catalog], and returns what it picks.
  Future<PickedType> showConcreteTypePicker(
    String label, {
    required skir.TypeDefinitionId expected,
    required CheckedEditorCatalog catalog,
  }) async {
    final picked = PickedType();
    await pumpPanel(
      const [],
      at: PanelLocation.component(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              picked.selection = await showCreationConcreteTypePicker(
                context,
                expected: skir.TypeSelection.createComplete(
                  definition: expected,
                  arguments: const [],
                ),
                catalog: catalog,
              );
            },
            child: Text(label),
          ),
        ),
      ),
    );
    return picked;
  }

  /// Types [query] into the open type search and lets it settle.
  Future<void> searchTypes(String query) async {
    await enterText(typeSearchField, query);
    await pumpAndSettle();
  }

  /// Searches the open type search for [name] and chooses its result.
  Future<void> chooseType(String name) async {
    await searchTypes(name);
    await tap(
      find.descendant(
        of: find.byType(SearchResultCard),
        matching: find.text(name),
      ),
    );
    await pumpAndSettle();
  }
}

/// The ready preview of changing the type arguments of `variable:1` to
/// [next] in [catalog], with no edit and clearing the [cleared] values.
skir.PreviewTypeArgumentChangeResponse readyTypeArgumentPreview(
  CheckedEditorCatalog catalog,
  skir.TypeSelection next, {
  List<skir.ValueLocation> cleared = const [],
}) => skir.PreviewTypeArgumentChangeResponse.createReady(
  resource: skir.ResourceId(value: "variable:1"),
  next: next,
  edit: skir.PreparedEdit(
    catalog: catalog.snapshot.generation,
    expectations: const [],
    intents: const [],
  ),
  linkRepairs: const [],
  clearedLocations: cleared,
);
