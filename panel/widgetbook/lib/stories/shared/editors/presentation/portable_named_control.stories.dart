import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

/// Binding shapes that decide whether the named payload can be edited.
enum NamedControlScenario { available, missingBinding, unnamedValue, unlocated }

@widgetbook.UseCase(
  name: "Named payload binding",
  type: PortableNamedControlHost,
)
Widget portableNamedControlHostUseCase(BuildContext context) =>
    PortableNamedControlHostStory(
      scenario: context.knobs.object.dropdown(
        label: "Binding",
        options: NamedControlScenario.values,
        initialOption: NamedControlScenario.available,
        labelBuilder: (scenario) => switch (scenario) {
          NamedControlScenario.available => "Named value with location",
          NamedControlScenario.missingBinding => "Missing binding",
          NamedControlScenario.unnamedValue => "Plain record value",
          NamedControlScenario.unlocated => "No authored location",
        },
      ),
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 420,
        min: 260,
        max: 640,
      ),
    );

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
class PortableNamedControlHostStory extends HookWidget {
  const PortableNamedControlHostStory({
    this.scenario = NamedControlScenario.available,
    this.width = 420,
    super.key,
  });

  final NamedControlScenario scenario;
  final double width;

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
      Iterable<PortableExpressionRead> reads = const [],
    }) {
      element.value = skir.DataValue.createRecord(
        fields: [skir.FieldValue(name: "style", value: value)],
      );
      writes.value++;
      return const PortablePresentationWriteApplied();
    }

    return FakeApp(
      child: SizedBox(
        width: width,
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
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
              setBinding: write,
              unavailableBuilder: (context, message) =>
                  Text(message, style: TextStyle(color: context.colors.danger)),
              builder: (context, presentation, payload) =>
                  _StylePayloadEditor(payload: payload),
            ),
            Text("Writes: ${writes.value}"),
          ],
        ),
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
