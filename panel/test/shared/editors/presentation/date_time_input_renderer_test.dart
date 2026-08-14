import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("renders and updates timestamp bindings", (tester) async {
    await tester.pumpTestApp(child: _renderer());
    expect(find.byType(DateTimePickerField), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "2028-02-29 07:06:05");
    await tester.pumpAndSettle();
    final field = tester.widget<DateTimePickerField>(
      find.byType(DateTimePickerField),
    );
    expect(field.value, DateTime.utc(2028, 2, 29, 7, 6, 5, 123, 456));
  });

  testWidgets("renders a diagnostic when both parts are disabled", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(includeDate: false, includeTime: false),
    );
    expect(
      find.text("Date and time control must enable at least one part"),
      findsOneWidget,
    );
    expect(find.byType(DateTimePickerField), findsNothing);
  });

  testWidgets("renders a diagnostic for non timestamp bindings", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("not a timestamp"),
      ),
    );
    expect(
      find.text("Control does not accept its binding type"),
      findsOneWidget,
    );
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

Widget _renderer({
  bool includeDate = true,
  bool includeTime = true,
  TypeExpression type = const TimestampType(),
  DataValue? value,
}) => EditorProtocolRenderer(
  envelope: TypedValueEnvelope(
    rootType: ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "DateTimeInput"),
      revision: 1,
    ),
    rootValue:
        value ??
        TimestampValue(DateTime.utc(2024, 8, 12, 18, 30, 45, 123, 456)),
  ),
  typeCatalog: TypeCatalog([
    TypeDefinition(
      id: ResolvedTypeRef(
        id: const QualifiedTypeId(namespace: "test", name: "DateTimeInput"),
        revision: 1,
      ),
      kind: NominalTypeKind.concrete,
      representation: type,
    ),
  ]),
  presentation: PresentationNode(
    id: "dateTime",
    element: DateTimeInputElement(
      control: const BoundControl(binding: _rootBinding),
      includeDate: includeDate,
      includeTime: includeTime,
    ),
  ),
);
