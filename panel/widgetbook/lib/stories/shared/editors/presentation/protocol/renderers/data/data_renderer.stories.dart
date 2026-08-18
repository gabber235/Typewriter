import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "shared/editors/presentation/protocol/renderers/data";
const _conditionalPath = "$_path/Conditional";
const _repeatedPath = "$_path/Repeated";
const _itemBinding = BindingReference(bindingId: BindingId(1));
final _conditionBinding = rootBinding.at(
  DataPath.root.field("showTimedDialogue"),
);
final _dialogueTextBinding = rootBinding.at(DataPath.root.field("text"));
final _typingDurationBinding = rootBinding.at(
  DataPath.root.field("typingDuration"),
);
final _waitDurationBinding = rootBinding.at(
  DataPath.root.field("waitDuration"),
);
final _allowSkipBinding = rootBinding.at(DataPath.root.field("allowSkip"));

final dataRendererScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.diagnostic,
    name: "Diagnostic",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "diagnostic",
      PresentationElement.diagnostic([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message:
              "This value cannot be displayed using the requested renderer.",
        ),
      ]),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.defaultPresentation,
    name: "Default presentation",
    type: const StringType(),
    value: const StringValue("Generated control"),
    presentation: storyNode(
      "defaultPresentation",
      const PresentationElement.defaultPresentation(binding: rootBinding),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.typedField,
    name: "Typed field",
    type: const StringType(),
    value: const StringValue("Typed field value"),
    presentation: storyNode(
      "typedField",
      const PresentationElement.typedField(
        binding: rootBinding,
        expectedType: StringType(),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.conditional,
    name: "Conditional",
    type: const BooleanType(),
    value: const BooleanValue(true),
    presentation: storyNode(
      "conditional",
      PresentationElement.conditional(
        condition: bindingExpression(rootBinding, const BooleanType()),
        whenTrue: storyNode(
          "conditionTrue",
          PresentationElement.text("Conditional content".asStringLiteral),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.repeated,
    name: "Repeated",
    type: const ListType(element: StringType()),
    value: const ListValue([
      StringValue("Meet the guide"),
      StringValue("Find the hidden path"),
      StringValue("Return to the village"),
    ]),
    presentation: storyNode(
      "repeated",
      PresentationElement.repeated(
        source: bindingExpression(
          rootBinding,
          const ListType(element: StringType()),
        ),
        itemBindingId: const BindingId(1),
        presentation: SequencePresentation(
          item: storyNode(
            "repeatedItem",
            PresentationElement.section(
              child: storyNode(
                "repeatedText",
                PresentationElement.text(
                  bindingExpression(_itemBinding, const StringType()),
                ),
              ),
            ),
          ),
          empty: storyNode(
            "repeatedEmpty",
            PresentationElement.text(
              "No objectives configured".asStringLiteral,
            ),
          ),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.scopedBinding,
    name: "Scoped binding",
    type: const StringType(),
    value: const StringValue("Value from a scoped alias"),
    presentation: storyNode(
      "scopedBinding",
      PresentationElement.scopedBinding(
        binding: rootBinding,
        scopeBindingId: const BindingId(1),
        child: storyNode(
          "scopedText",
          PresentationElement.text(
            bindingExpression(_itemBinding, const StringType()),
          ),
        ),
      ),
    ),
  ),
];

@widgetbook.UseCase(
  name: "Diagnostic",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget diagnosticRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[0]);

@widgetbook.UseCase(
  name: "Default presentation",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget defaultPresentationRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[1]);

@widgetbook.UseCase(
  name: "Typed field",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget typedFieldRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[2]);

@widgetbook.UseCase(
  name: "Interactive",
  type: EditorProtocolRenderer,
  path: _conditionalPath,
)
Widget conditionalRendererUseCase(BuildContext context) =>
    rendererStory(context, conditionalRendererScenario);

final conditionalRendererScenario = RendererStoryScenario(
  kind: RendererStoryKind.conditional,
  name: "Conditional",
  type: RecordType(
    fields: {
      "showTimedDialogue": TypeField(
        name: "showTimedDialogue",
        type: BooleanType(),
      ),
      "text": TypeField(name: "text", type: StringType(maximumLength: 240)),
      "typingDuration": TypeField(name: "typingDuration", type: DurationType()),
      "waitDuration": TypeField(name: "waitDuration", type: DurationType()),
      "allowSkip": TypeField(name: "allowSkip", type: BooleanType()),
    },
  ),
  value: RecordValue({
    "showTimedDialogue": BooleanValue(true),
    "text": StringValue("The lanterns will guide you through the old forest."),
    "typingDuration": DurationValue(Duration(seconds: 2)),
    "waitDuration": DurationValue(Duration(seconds: 4)),
    "allowSkip": BooleanValue(true),
  }),
  presentation: storyNode(
    "conditional",
    PresentationElement.tabs(
      initiallySelectedTabId: "preview",
      tabs: [
        TabItem(
          id: "preview",
          label: "Preview".asStringLiteral,
          child: storyNode(
            "conditionalPreview",
            PresentationElement.column(
              spacing: 16,
              children: [
                storyInput(
                  "conditionInput",
                  label: "Timed dialogue fields",
                  binding: _conditionBinding,
                  description: "This local Boolean is the conditional input.",
                  showHeader: true,
                  build: PresentationElement.toggleInput,
                ),
                storyNode(
                  "conditionResult",
                  PresentationElement.conditional(
                    condition: bindingExpression(
                      _conditionBinding,
                      const BooleanType(),
                    ),
                    whenTrue: storyNode(
                      "timedDialogueEditor",
                      PresentationElement.section(
                        child: storyNode(
                          "timedDialogueFields",
                          PresentationElement.column(
                            spacing: 12,
                            children: [
                              storyInput(
                                "dialogueText",
                                label: "Text",
                                binding: _dialogueTextBinding,
                                description: "The message shown to the player.",
                                build: (control) =>
                                    PresentationElement.textInput(
                                      control: control,
                                      multiline: true,
                                      placeholder:
                                          "What should the speaker say?"
                                              .asStringLiteral,
                                    ),
                              ),
                              storyInput(
                                "dialogueTypingDuration",
                                label: "Typing duration",
                                binding: _typingDurationBinding,
                                description:
                                    "Time used to animate the full message.",
                                build: PresentationElement.durationInput,
                              ),
                              storyInput(
                                "dialogueWaitDuration",
                                label: "Wait duration",
                                binding: _waitDurationBinding,
                                description:
                                    "Pause before the dialogue continues.",
                                build: PresentationElement.durationInput,
                              ),
                              storyInput(
                                "dialogueAllowSkip",
                                label: "Allow skip",
                                binding: _allowSkipBinding,
                                description:
                                    "Let the confirmation key complete or skip the dialogue.",
                                showHeader: true,
                                build: PresentationElement.toggleInput,
                              ),
                            ],
                          ),
                        ),
                      ),
                      header: PresentationHeader(
                        title: "Timed dialogue".asStringLiteral.asHeaderTitle,
                      ),
                    ),
                    whenFalse: storyNode(
                      "timedDialogueHidden",
                      PresentationElement.section(
                        child: storyNode(
                          "timedDialogueHiddenText",
                          PresentationElement.text(
                            "Enable the condition to continue editing the same dialogue."
                                .asStringLiteral,
                          ),
                        ),
                      ),
                      header: PresentationHeader(
                        title: "Timed dialogue hidden"
                            .asStringLiteral
                            .asHeaderTitle,
                        description:
                            "The false branch replaces the field editor while preserving its bound values."
                                .asStringLiteral,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        TabItem(
          id: "resolution",
          label: "Resolution".asStringLiteral,
          child: storyNode(
            "conditionalResolution",
            PresentationElement.markdown(
              "### How it resolves\n\n"
                      "1. The condition reads `showTimedDialogue`.\n"
                      "2. `true` renders the timed dialogue fields.\n"
                      "3. `false` renders the explicit fallback instead.\n\n"
                      "The field values come from the same binding in both "
                      "branches. Hiding and restoring the editor preserves "
                      "local edits without recreating the Widgetbook story."
                  .asStringLiteral,
            ),
          ),
        ),
      ],
    ),
  ),
);

@widgetbook.UseCase(
  name: "Interactive list",
  type: EditorProtocolRenderer,
  path: _repeatedPath,
)
Widget repeatedRendererUseCase(BuildContext context) =>
    rendererStory(context, _repeatedScenario(_repeatedItems(context)));

List<StringValue> _repeatedItems(BuildContext context) {
  final count = context.knobs.int.slider(
    label: "Item count",
    initialValue: 3,
    min: 0,
    max: 3,
  );
  final items = [
    context.knobs.string(label: "Item 1", initialValue: "Meet the guide"),
    context.knobs.string(label: "Item 2", initialValue: "Find the hidden path"),
    context.knobs.string(
      label: "Item 3",
      initialValue: "Return to the village",
    ),
  ];

  return items.take(count).map(StringValue.new).toList();
}

RendererStoryScenario _repeatedScenario(
  List<StringValue> items,
) => RendererStoryScenario(
  kind: RendererStoryKind.repeated,
  name: "Repeated",
  type: const ListType(element: StringType()),
  value: ListValue(items),
  presentation: storyNode(
    "repeated",
    PresentationElement.column(
      children: [
        storyNode(
          "repeatedHint",
          PresentationElement.text(
            "Change Item count or an item value in the knobs panel. Each "
                    "list value is bound to the template alias, so the card "
                    "is rendered once per item."
                .asStringLiteral,
          ),
        ),
        storyNode(
          "repeatedItems",
          PresentationElement.repeated(
            source: bindingExpression(
              rootBinding,
              const ListType(element: StringType()),
            ),
            itemBindingId: const BindingId(1),
            presentation: SequencePresentation(
              item: storyNode(
                "repeatedItem",
                PresentationElement.section(
                  child: storyNode(
                    "repeatedText",
                    PresentationElement.text(
                      bindingExpression(_itemBinding, const StringType()),
                    ),
                  ),
                ),
              ),
              empty: storyNode(
                "repeatedEmpty",
                PresentationElement.text(
                  "No items means the empty presentation is rendered."
                      .asStringLiteral,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

final customRepeatedEmptyScenario = RendererStoryScenario(
  kind: RendererStoryKind.repeated,
  name: "Custom repeated empty state",
  type: const ListType(element: StringType()),
  value: const ListValue([]),
  presentation: storyNode(
    "emptyRepeated",
    PresentationElement.tabs(
      initiallySelectedTabId: "preview",
      tabs: [
        TabItem(
          id: "preview",
          label: "Preview".asStringLiteral,
          child: storyNode(
            "emptyPreview",
            PresentationElement.repeated(
              source: bindingExpression(
                rootBinding,
                const ListType(element: StringType()),
              ),
              itemBindingId: const BindingId(1),
              presentation: SequencePresentation(
                item: storyNode(
                  "repeatedTemplate",
                  PresentationElement.text(
                    bindingExpression(_itemBinding, const StringType()),
                  ),
                ),
                empty: storyNode(
                  "customEmpty",
                  PresentationElement.section(
                    child: storyNode(
                      "customEmptyText",
                      PresentationElement.text(
                        "Add the first objective when the quest is ready."
                            .asStringLiteral,
                      ),
                    ),
                  ),
                  header: PresentationHeader(
                    title: "No objectives yet".asStringLiteral.asHeaderTitle,
                    description:
                        "The empty presentation replaces the objective template."
                            .asStringLiteral,
                  ),
                ),
              ),
            ),
          ),
        ),
        TabItem(
          id: "resolution",
          label: "Resolution".asStringLiteral,
          child: storyNode(
            "emptyResolution",
            PresentationElement.markdown(
              "### Empty resolution\n\n"
                      "The objective source resolves to `[]`, so the template "
                      "renders zero times. The renderer then uses the explicit "
                      "`empty` presentation. If `empty` were omitted, the "
                      "output would occupy no space."
                  .asStringLiteral,
            ),
          ),
        ),
      ],
    ),
  ),
);

@widgetbook.UseCase(
  name: "Custom empty state",
  type: EditorProtocolRenderer,
  path: _repeatedPath,
)
Widget customRepeatedEmptyUseCase(BuildContext context) =>
    rendererStory(context, customRepeatedEmptyScenario);

@widgetbook.UseCase(
  name: "Scoped binding",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget scopedBindingRendererUseCase(BuildContext context) => rendererStory(
  context,
  _scopedBindingScenario(
    context.knobs.string(
      label: "Root value",
      initialValue: "Value from a scoped alias",
    ),
  ),
);

RendererStoryScenario _scopedBindingScenario(
  String value,
) => RendererStoryScenario(
  kind: RendererStoryKind.scopedBinding,
  name: "Scoped binding",
  type: const StringType(),
  value: StringValue(value),
  presentation: storyNode(
    "scopedBinding",
    PresentationElement.column(
      children: [
        storyNode(
          "scopedBindingHint",
          PresentationElement.text(
            "Change Root value in the knobs panel. The scoped binding maps "
                    "the root value to its alias, and the child resolves that "
                    "alias instead of reading the root directly."
                .asStringLiteral,
          ),
        ),
        storyNode(
          "scopedBindingResult",
          PresentationElement.scopedBinding(
            binding: rootBinding,
            scopeBindingId: const BindingId(1),
            child: storyNode(
              "scopedText",
              PresentationElement.section(
                child: storyNode(
                  "scopedValue",
                  PresentationElement.text(
                    bindingExpression(_itemBinding, const StringType()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
