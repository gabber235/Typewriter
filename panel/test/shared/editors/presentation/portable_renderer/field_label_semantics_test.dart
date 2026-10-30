import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/testing.dart";

final _binding = skir.ExpressionBindingId(value: "root");
final _reference = skir.BindingRef(
  bindingId: _binding,
  path: skir.ValuePath(segments: const []),
);
final _control =
    (skir.BoundControl.mutable()
          ..binding = _reference
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

  for (final (kind, element, value, section) in [
    (
      "text",
      textInputElement(_reference),
      skir.DataValue.wrapStringValue("Quest objective"),
      "Title",
    ),
    (
      "numeric",
      skir.PresentationElement.wrapNumericInput(
        (skir.NumericControl.mutable()
              ..control = presentationControl(_reference))
            .toFrozen(),
      ),
      skir.DataValue.wrapInteger("12"),
      "Count",
    ),
    (
      "color",
      colorInputElement(_reference),
      skir.DataValue.wrapInteger(0xFFAABBCC.toString()),
      "Color",
    ),
  ]) {
    testWidgets("a $kind field named only by its section announces the "
        "section title", (tester) async {
      await tester.showBoundElement(
        element,
        value,
        binding: _binding,
        section: section,
      );

      expect(
        [for (final field in visibleTextFields()) field.spoken],
        [section],
      );
    });
  }

  for (final (element, value, section, typed) in [
    (
      textInputElement(_reference),
      skir.DataValue.wrapStringValue("Quest objective"),
      "Title",
      "Side quest",
    ),
    (
      colorInputElement(_reference),
      skir.DataValue.wrapInteger(0xFFAABBCC.toString()),
      "Color",
      "#112233",
    ),
  ]) {
    testWidgets("a screen reader focusing the $section field can type into "
        "it", (tester) async {
      final panel = await tester.showBoundElement(
        element,
        value,
        binding: _binding,
        section: section,
      );
      final field = panel.field(section);

      await field.focusFromScreenReader();
      await field.edit(typed);

      expect(field.value, typed);
    });
  }
}
