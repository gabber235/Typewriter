import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";

enum RendererStoryKind {
  diagnostic,
  defaultPresentation,
  text,
  markdown,
  icon,
  image,
  badge,
  chip,
  progress,
  typedField,
  conditional,
  repeated,
  scopedBinding,
  textInput,
  numericInput,
  toggleInput,
  selectInput,
  sliderInput,
  dateTimeInput,
  durationInput,
  colorInput,
  searchInput,
  bytesInput,
  enumInput,
  namedInput,
  listInput,
  mapInput,
  recordInput,
  polymorphicInput,
  button,
  iconButton,
  menu,
  tooltip,
  column,
  row,
  wrap,
  stack,
  grid,
  section,
  tabs,
  divider,
  spacer,
}

class RendererStoryScenario {
  const RendererStoryScenario({
    required this.kind,
    required this.name,
    required this.type,
    required this.value,
    required this.presentation,
    this.definitions = const [],
    this.diagnostics = const [],
  });

  final RendererStoryKind kind;
  final String name;
  final TypeExpression type;
  final DataValue value;
  final PresentationNode presentation;
  final List<TypeDefinition> definitions;
  final List<TypeDiagnostic> diagnostics;
}

class PresentationRendererStory extends StatelessWidget {
  const PresentationRendererStory({
    required this.scenario,
    required this.width,
    this.readOnly = false,
    this.colorLibraryStorage,
    super.key,
  });

  final RendererStoryScenario scenario;
  final double width;
  final bool readOnly;
  final ColorLibraryStorage? colorLibraryStorage;

  @override
  Widget build(BuildContext context) => FakeApp(
    overrides: [
      if (colorLibraryStorage case final storage?)
        colorLibraryStorageProvider.overrideWithValue(storage),
    ],
    child: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Section(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EditorProtocolRenderer(
                  envelope: TypedValueEnvelope(
                    rootType: rendererStoryRoot,
                    rootValue: scenario.value,
                  ),
                  typeCatalog: TypeCatalog([
                    TypeDefinition(
                      id: rendererStoryRoot,
                      kind: NominalTypeKind.concrete,
                      representation: scenario.type,
                    ),
                    ...scenario.definitions,
                  ]),
                  presentation: scenario.presentation,
                  diagnostics: scenario.diagnostics,
                  readOnly: readOnly,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const ActionRow(),
    ),
  );
}

Widget rendererStory(BuildContext context, RendererStoryScenario scenario) =>
    PresentationRendererStory(
      scenario: scenario,
      width: context.knobs.double.slider(
        label: "Editor width",
        initialValue: 520,
        min: 280,
        max: 760,
      ),
      readOnly: context.knobs.boolean(label: "Read only"),
    );

final rendererStoryRoot = ResolvedTypeRef(
  id: const QualifiedTypeId(namespace: "widgetbook", name: "RendererStory"),
  revision: 1,
);

extension RendererStoryElementKind on PresentationElement {
  RendererStoryKind get rendererStoryKind => switch (this) {
    DiagnosticElement() => RendererStoryKind.diagnostic,
    DefaultPresentationElement() => RendererStoryKind.defaultPresentation,
    TextElement() => RendererStoryKind.text,
    MarkdownElement() => RendererStoryKind.markdown,
    IconElement() => RendererStoryKind.icon,
    ImageElement() => RendererStoryKind.image,
    BadgeElement() => RendererStoryKind.badge,
    ChipElement() => RendererStoryKind.chip,
    ProgressElement() => RendererStoryKind.progress,
    TypedFieldElement() => RendererStoryKind.typedField,
    ConditionalElement() => RendererStoryKind.conditional,
    RepeatedElement() => RendererStoryKind.repeated,
    ScopedBindingElement() => RendererStoryKind.scopedBinding,
    CollectionLookupElement() => RendererStoryKind.defaultPresentation,
    CollectionGraphElement() => RendererStoryKind.defaultPresentation,
    TextInputElement() => RendererStoryKind.textInput,
    NumericInputElement() => RendererStoryKind.numericInput,
    ToggleInputElement() => RendererStoryKind.toggleInput,
    SelectInputElement() => RendererStoryKind.selectInput,
    SliderInputElement() => RendererStoryKind.sliderInput,
    DateTimeInputElement() => RendererStoryKind.dateTimeInput,
    DurationInputElement() => RendererStoryKind.durationInput,
    ColorInputElement() => RendererStoryKind.colorInput,
    SearchInputElement() => RendererStoryKind.searchInput,
    BytesInputElement() => RendererStoryKind.bytesInput,
    EnumInputElement() => RendererStoryKind.enumInput,
    NamedInputElement() => RendererStoryKind.namedInput,
    ListInputElement() => RendererStoryKind.listInput,
    MapInputElement() => RendererStoryKind.mapInput,
    RecordInputElement() => RendererStoryKind.recordInput,
    PolymorphicInputElement() => RendererStoryKind.polymorphicInput,
    ButtonElement() => RendererStoryKind.button,
    IconButtonElement() => RendererStoryKind.iconButton,
    MenuElement() => RendererStoryKind.menu,
    TooltipElement() => RendererStoryKind.tooltip,
    ColumnElement() => RendererStoryKind.column,
    RowElement() => RendererStoryKind.row,
    WrapElement() => RendererStoryKind.wrap,
    StackElement() => RendererStoryKind.stack,
    GridElement() => RendererStoryKind.grid,
    SectionElement() => RendererStoryKind.section,
    PaddingElement() => RendererStoryKind.section,
    PresentationSlotElement() => RendererStoryKind.defaultPresentation,
    TabsElement() => RendererStoryKind.tabs,
    DividerElement() => RendererStoryKind.divider,
    SpacerElement() => RendererStoryKind.spacer,
  };
}
