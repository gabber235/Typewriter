import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("named payload edits write back through its binding", (
    tester,
  ) async {
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(_NamedControlHost()),
    );
    expect(
      find.text("MessageStyle at element:welcome_message style"),
      findsOneWidget,
    );
    expect(find.text("Welcome to the village"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "Good evening");
    await tester.pump();
    expect(find.text("Writes: 1"), findsOneWidget);
    expect(find.text("Good evening"), findsOneWidget);
  });

  for (final (scenario, message) in [
    (NamedControlScenario.missingBinding, "The control binding is unavailable"),
    (
      NamedControlScenario.unnamedValue,
      "The control binding is not a named value",
    ),
    (
      NamedControlScenario.unlocated,
      "The control binding has no authored location",
    ),
  ]) {
    testWidgets("${scenario.name} renders the unavailable state", (
      tester,
    ) async {
      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(_NamedControlHost(scenario: scenario)),
      );
      expect(find.text(message), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  }
}

/// Binding shapes that decide whether the named payload can be edited.
enum NamedControlScenario { available, missingBinding, unnamedValue, unlocated }

final _messageBinding = skir.ExpressionBindingId(value: "element");
final _styleReference = skir.BindingRef(
  bindingId: _messageBinding,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: "style")]),
);
final _styleType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "typewriter",
      name: "MessageStyle",
    ),
    revision: 1,
  ),
  arguments: const [],
);

skir.DataValue _style(String title) => skir.DataValue.createRecord(
  fields: [
    skir.FieldValue(
      name: "title",
      value: skir.DataValue.wrapStringValue(title),
    ),
    skir.FieldValue(name: "typing", value: skir.DataValue.wrapBoolean(true)),
  ],
);

/// Resolves a message style binding and renders its named payload through a
/// local builder whose replacements write back the same named type.
class _NamedControlHost extends HookWidget {
  const _NamedControlHost({this.scenario = NamedControlScenario.available});

  final NamedControlScenario scenario;

  @override
  Widget build(BuildContext context) {
    final element = useState(
      skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "style",
            value: skir.DataValue.createNamed(
              actualType: _styleType,
              payload: _style("Welcome to the village"),
            ),
          ),
        ],
      ),
    );
    final writes = useState(0);
    final style = switch (scenario) {
      NamedControlScenario.unnamedValue => skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(name: "style", value: _style("Unnamed style")),
        ],
      ),
      _ => element.value,
    };
    final bindings = {
      if (scenario != NamedControlScenario.missingBinding)
        _messageBinding: PortableExpressionBinding(
          value: style,
          location: scenario == NamedControlScenario.unlocated
              ? null
              : skir.ValueLocation(
                  resource: skir.ResourceId(value: "element:welcome_message"),
                  path: editorRootPath,
                ),
        ),
    };
    PortablePresentationWriteResult write(
      skir.BindingRef reference,
      skir.DataValue value, {
      Iterable<skir.ValueLocation> reads = const [],
    }) {
      element.value = skir.DataValue.createRecord(
        fields: [skir.FieldValue(name: "style", value: value)],
      );
      writes.value++;
      return const PortablePresentationWriteApplied();
    }

    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PortableNamedControlHost(
            control: skir.NamedControl(
              control: skir.BoundControl(
                binding: _styleReference,
                label: null,
                description: null,
                prefix: null,
                semanticLabel: null,
              ),
              payloadPresentation: null,
              appearance: null,
              content: null,
            ),
            bindings: bindings,
            setBinding: write,
            unavailableBuilder: (context, message) =>
                Text(message, style: TextStyle(color: context.colors.danger)),
            builder: (context, presentation, payload) =>
                _StylePayloadEditor(payload: payload),
          ),
          Text("Writes: ${writes.value}"),
        ],
      ),
    );
  }
}

class _StylePayloadEditor extends StatelessWidget {
  const _StylePayloadEditor({required this.payload});

  final PortableNamedPayload payload;

  @override
  Widget build(BuildContext context) {
    final title = payload.value.authoredField("title")?.authoredString ?? "";
    final location = [
      payload.location.resource.value,
      for (final segment in payload.location.path.segments)
        if (segment case skir.PathSegment_fieldWrapper(:final value))
          value.name,
    ].join(" ");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          "${_typeName(payload.actualType)} at $location",
          style: Theme.of(context).textTheme.labelMedium,
        ),
        ValidatedTextField<String>(
          value: title,
          name: "title",
          onChanged: (next) => payload.replace(_style(next)),
        ),
      ],
    );
  }
}

String _typeName(skir.NamedTypeUse type) => switch (type.definition.typeId) {
  skir.TypeId_qualifiedWrapper(:final value) => value.name,
  _ => "Named value",
};
