import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/drivers/authoring/surface_driver.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// Showing an [AuthoredDraft] in the panel.
extension AuthoredDraftViews on AuthoredDraft {
  /// Opens a Realm saving this draft and shows its resource above it as a
  /// disabled item card of [width] in a one cell graph node.
  Future<void> showItemCard(
    WidgetTester tester, {
    required double width,
  }) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realmServing(draft.toDocument()),
      heldSaves,
    ]);
    await panel.showAbove(
      at: Alignment.topLeft,
      Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AuthoredResourceEditor(
                resource: resource,
                document: draft.toDocument(),
                role: skir.PresentationRole.item,
                budget: skir.EvaluationBudget(
                  maxSteps: 100,
                  maxCollectionItems: 100,
                ),
                enabled: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}
