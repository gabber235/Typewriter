import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";

/// The open type chooser: a search over resource types, where the author
/// types part of a name and chooses one of the matching types.
final class TypeChooserDriver extends ComponentDriver {
  TypeChooserDriver(super.tester);

  /// Shows a button [label] that opens the chooser of concrete resource
  /// types descending from [expected] in [catalog], presses it, and returns
  /// the open chooser with the type it picks once it closes.
  static Future<(TypeChooserDriver, FlowOutcome<skir.TypeSelection>)>
  openConcrete(
    WidgetTester tester,
    String label, {
    required skir.TypeDefinitionId expected,
    required CheckedEditorCatalog catalog,
  }) async {
    final (_, outcome) = await tester.openFromButton<skir.TypeSelection>(
      (context) => showCreationConcreteTypePicker(
        context,
        expected: skir.TypeSelection.createComplete(
          definition: expected,
          arguments: const [],
        ),
        catalog: catalog,
      ),
      label: label,
    );
    return (TypeChooserDriver(tester), outcome);
  }

  /// The text field the author searches types in.
  Finder get searchField => find.descendant(
    of: find.byType(QueryBar),
    matching: find.byType(EditableText),
  );

  /// Whether the search field holds the keyboard focus.
  bool get searchFocused =>
      tester.widget<EditableText>(searchField).focusNode.hasPrimaryFocus;

  /// Types [query] into the search and lets the matching types show.
  Future<void> search(String query) async {
    await tester.enterText(searchField, query);
    await tester.pumpAndSettle();
  }

  /// The search result showing the type [name].
  Finder result(String name) => find.descendant(
    of: find.byType(SearchResultCard),
    matching: find.text(name),
  );

  /// Searches for [name] and chooses its result.
  Future<void> choose(String name) async {
    await search(name);
    await tester.tap(result(name));
    await tester.pumpAndSettle();
  }
}
