import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/presentation/type_choosers.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/authoring/type_chooser_driver.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";

/// A type argument editor shown on its own, whose Realm preview of a type
/// change is always ready: the author chooses arguments and asks to review
/// the change.
final class TypeArgumentEditorDriver extends ComponentDriver {
  TypeArgumentEditorDriver._(super.tester);

  /// The selection the last review asked the Realm to preview; null before
  /// the first review.
  skir.TypeSelection? requested;

  /// Shows the editor of [selection] over [catalog].
  static Future<TypeArgumentEditorDriver> show(
    WidgetTester tester, {
    required skir.TypeSelection selection,
    required CheckedEditorCatalog catalog,
  }) async {
    final driver = TypeArgumentEditorDriver._(tester);
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Scaffold(
          body: AuthoredTypeArgumentEditor(
            selection: selection,
            catalog: catalog,
            preview: (next) async {
              driver.requested = next;
              return readyTypeArgumentPreview(catalog, next);
            },
            commit: (_) async => const EditStageResult.staged(EditGroupId(1)),
          ),
        ),
      ),
    );
    return driver;
  }

  /// Chooses the type [name] for the first argument that has none yet.
  Future<void> chooseNext(String name) async {
    await tester.tap(find.text("Choose a type").first);
    await tester.pumpAndSettle();
    await TypeChooserDriver(tester).choose(name);
  }

  /// Asks the Realm to preview the changed arguments.
  Future<void> review() async {
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();
  }
}
