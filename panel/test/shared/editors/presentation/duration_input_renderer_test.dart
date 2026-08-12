import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("parses compound units and propagates the typed duration", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const DurationType(),
        value: const Duration(minutes: 5),
        showValue: true,
      ),
    );

    await tester.enterText(find.byType(TextFormField), "1h 30min 250ms");
    await tester.pump();

    expect(find.text("1:30:00.250000"), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets("shows invalid duration syntax without propagating it", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const DurationType(),
        value: const Duration(minutes: 5),
        showValue: true,
      ),
    );

    await tester.enterText(find.byType(TextFormField), "1");
    await tester.pump();

    expect(find.text("Invalid duration format"), findsOneWidget);
    expect(find.text("0:05:00.000000"), findsOneWidget);
  });

  testWidgets("shows minimum and maximum bound feedback", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const DurationType(
          minimum: Duration(hours: 2),
          maximum: Duration(hours: 4),
        ),
        value: const Duration(hours: 3),
        showValue: true,
      ),
    );

    await tester.enterText(find.byType(TextFormField), "1h");
    await tester.pump();

    expect(find.text("Value is below its minimum"), findsOneWidget);
    expect(find.text("3:00:00.000000"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "5h");
    await tester.pump();

    expect(find.text("Value exceeds its maximum"), findsOneWidget);
    expect(find.text("3:00:00.000000"), findsOneWidget);
  });

  testWidgets("allows negative durations when no minimum is declared", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const DurationType(),
        value: Duration.zero,
        showValue: true,
      ),
    );

    await tester.enterText(find.byType(TextFormField), "-1s 250ms");
    await tester.pump();

    expect(find.text("-0:00:01.250000"), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets("keeps the duration field read only", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const DurationType(),
        value: const Duration(minutes: 5),
        showValue: true,
        readOnly: true,
      ),
    );

    final field = tester.widget<ValidatedTextField<Duration>>(
      find.byType(ValidatedTextField<Duration>),
    );
    expect(field.readOnly, isTrue);

    await tester.enterText(find.byType(TextFormField), "10min");
    await tester.pump();

    expect(find.text("0:05:00.000000"), findsOneWidget);
  });

  testWidgets("shows readable valid feedback", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const DurationType(),
        value: const Duration(minutes: 5),
      ),
    );

    await tester.enterText(find.byType(TextFormField), "1h 30min");
    await tester.pump();

    expect(find.text("Valid Duration: 1 hour 30 minutes"), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

Widget _renderer({
  required DurationType type,
  required Duration value,
  bool showValue = false,
  bool readOnly = false,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "durationInput"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(
      rootType: root,
      rootValue: DurationValue(value),
    ),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    presentation: PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          const PresentationNode(
            id: "duration",
            element: DurationInputElement(
              BoundControl(
                binding: _rootBinding,
                label: TypedExpression(
                  resultType: StringType(),
                  expression: LiteralExpression(StringValue("Delay")),
                ),
              ),
            ),
          ),
          if (showValue)
            const PresentationNode(
              id: "value",
              element: TextElement(
                TypedExpression(
                  resultType: DurationType(),
                  expression: BindingExpression(_rootBinding),
                ),
              ),
            ),
        ],
      ),
    ),
    readOnly: readOnly,
  );
}
