import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The host of a control over a named value, such as a message style: it
/// hands the value to the control, which writes back through the binding,
/// or says why it cannot.
@widgetbook.UseCase(name: "Bindings", type: PortableNamedControlHost)
Widget portableNamedControlHostUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    PortableNamedControlHostStory(
      binding: context.knobs.object.dropdown(
        label: "Binding",
        options: NamedControlBinding.values,
        initialOption: NamedControlBinding.named,
        labelBuilder: (binding) => binding.label,
      ),
      width: context.knobs.width(const {"Inspector": 420, "Narrow": 240}),
    ),
  ),
);

/// What the control's binding holds in a [PortableNamedControlHostStory].
enum NamedControlBinding {
  named("Named value"),
  missing("Missing binding"),
  unnamed("Not a named value"),
  unlocated("No location");

  const NamedControlBinding(this.label);

  final String label;
}

/// A message style control whose writes the story keeps and names below.
class PortableNamedControlHostStory extends HookWidget {
  const PortableNamedControlHostStory({
    required this.binding,
    required this.width,
    super.key,
  });

  final NamedControlBinding binding;
  final double width;

  static final _element = skir.ExpressionBindingId(value: "element");
  static final _styleType = namedTypeUse("MessageStyle", namespace: "example");
  static final _control = skir.NamedControl(
    control: skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: _element,
        path: editorRootPath.field("style"),
      ),
      label: null,
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
    payloadPresentation: null,
    appearance: null,
    content: null,
  );

  @override
  Widget build(BuildContext context) {
    final title = useState("Welcome, traveller");
    final writes = useState(0);
    final style = recordEditorValue({
      "title": skir.DataValue.wrapStringValue(title.value),
    });
    final bindings = {
      if (binding != NamedControlBinding.missing)
        _element: PortableExpressionBinding(
          value: recordEditorValue({
            "style": binding == NamedControlBinding.unnamed
                ? style
                : skir.DataValue.createNamed(
                    actualType: _styleType,
                    payload: style,
                  ),
          }),
          location: binding == NamedControlBinding.unlocated
              ? null
              : skir.ValueLocation(
                  resource: skir.ResourceId(value: "element:message"),
                  path: editorRootPath,
                ),
        ),
    };
    return SizedBox(
      width: width,
      child: PortableNamedControlHost(
        control: _control,
        bindings: bindings,
        setBinding: (reference, value, {reads = const []}) {
          writes.value++;
          return const PortablePresentationWriteResult.applied();
        },
        unavailableBuilder: (context, message) {
          return Row(
            spacing: 8,
            children: [
              Icon(Icons.error_outline_rounded, color: context.colors.danger),
              Expanded(child: Text(message)),
            ],
          );
        },
        builder: (context, _, payload) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              const Text("Message style title"),
              EditorTextField(
                text: title.value,
                semanticLabel: "Message style title",
                onChanged: (next) {
                  title.value = next;
                  payload.replace(
                    recordEditorValue({
                      "title": skir.DataValue.wrapStringValue(next),
                    }),
                  );
                },
              ),
              Text(writes.value == 1 ? "1 write" : "${writes.value} writes"),
            ],
          );
        },
      ),
    );
  }
}
