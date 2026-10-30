import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/testing.dart";

final _binding = skir.ExpressionBindingId(value: "root");
final _control =
    (skir.BoundControl.mutable()
          ..binding = skir.BindingRef(
            bindingId: _binding,
            path: skir.ValuePath(segments: const []),
          )
          ..label = textLiteral("Title")
          ..description = textLiteral("Shown on the quest card"))
        .toFrozen();

void main() {
  for (final (kind, element, value) in [
    (
      "text",
      skir.PresentationElement.wrapTextInput(
        (skir.TextControl.mutable()..control = _control).toFrozen(),
      ),
      skir.DataValue.wrapStringValue("Quest objective"),
    ),
    (
      "numeric",
      skir.PresentationElement.wrapNumericInput(
        (skir.NumericControl.mutable()..control = _control).toFrozen(),
      ),
      skir.DataValue.wrapInteger("12"),
    ),
  ]) {
    testWidgets("a labeled $kind field announces its label once, on the "
        "field, with its description", (tester) async {
      await tester.showBoundElement(element, value, binding: _binding);

      final announced = find.semantics.byLabel(RegExp("Title"));
      expect(announced, findsOne);
      final field = announced.evaluate().single.getSemanticsData();
      expect(field.flagsCollection.isTextField, isTrue);
      expect(field.hint, "Shown on the quest card");
    });
  }
}
