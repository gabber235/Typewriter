import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

/// State driven numbers, transitions, a positioned stack, size, transform,
/// shadows, and adjusted and brightness colors, driven by interaction knobs.
@widgetbook.UseCase(
  name: "Paint primitives",
  type: PortablePresentationRenderer,
)
Widget portablePaintUseCase(BuildContext context) => portablePaintStory(
  interaction: PresentationInteraction(
    selected: context.knobs.boolean(label: "Selected"),
    hovered: context.knobs.boolean(label: "Hovered"),
    focused: context.knobs.boolean(label: "Focused"),
  ),
);

/// The compiled Book item presentation in a grid. Tab moves focus between
/// volumes, Enter or Space selects one, and hovering lifts it.
@widgetbook.UseCase(
  name: "Compiled Book item grid",
  type: PortablePresentationRenderer,
)
Widget compiledBookItemGridUseCase(BuildContext context) =>
    compiledBookItemGridStory(
      width: context.knobs.double.slider(
        label: "Grid width",
        initialValue: 760,
        min: 280,
        max: 1100,
      ),
    );

Widget portablePaintStory({
  PresentationInteraction interaction = const PresentationInteraction(),
}) => FakeApp(
  child: Material(
    child: Center(child: _PaintPrimitives(interaction: interaction)),
  ),
);

class _PaintPrimitives extends HookWidget {
  const _PaintPrimitives({required this.interaction});

  final PresentationInteraction interaction;

  @override
  Widget build(BuildContext context) {
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    return PresentationInteractionScope(
      value: interaction,
      child: PortablePresentationNodeRenderer(
        node: paintPrimitivesNode,
        scope: PortablePresentationScope(
          operations: operations,
          bindings: const {},
          budget: skir.EvaluationBudget(
            maxSteps: 10000,
            maxCollectionItems: 100,
          ),
        ),
      ),
    );
  }
}

final _selected = skir.PresentationStateMatch(
  required_: [skir.PresentationInteractionState.selected],
  excluded: const [],
);
final _hovered = skir.PresentationStateMatch(
  required_: [skir.PresentationInteractionState.hovered],
  excluded: const [],
);
final _focused = skir.PresentationStateMatch(
  required_: [skir.PresentationInteractionState.focused],
  excluded: const [],
);

/// Springs into the selected state and eases out of every other change.
final _selectMotion = skir.PresentationTransitionPolicy(
  rules: [
    skir.PresentationStateTransitionRule(
      match: _selected,
      transition: skir.PresentationTransition(
        milliseconds: 750,
        curve: skir.PresentationCurve.wrapElasticOut(0.9),
      ),
    ),
  ],
  fallback: skir.PresentationTransition(
    milliseconds: 300,
    curve: skir.PresentationCurve.emphasized,
  ),
);

skir.PresentationNumber _number(double value) =>
    skir.PresentationNumber.wrapValue(numberLiteral(value));

skir.PresentationNumber _when(
  skir.PresentationStateMatch match,
  double rest,
  double active,
) => skir.PresentationNumber.createStates(
  rules: [
    skir.PresentationStateNumberRule(
      match: match,
      value: numberLiteral(active),
    ),
  ],
  fallback: numberLiteral(rest),
);

skir.PresentationColor _literal(Color color) =>
    skir.PresentationColor.wrapValue(color.portableExpression);

const _accent = Color(0xff3f51b5);

skir.PresentationNode _surface(
  String id, {
  required skir.PresentationColor color,
  skir.PresentationNode? child,
  List<skir.PresentationShadow> shadows = const [],
}) => presentationNode(
  id,
  skir.PresentationElement.createContainer(
    child: child ?? presentationColumn("$id.empty", const []),
    border: null,
    backgroundColor: color,
    radius: skir.PresentationRadius.large,
    foregroundColor: null,
    transition: _selectMotion,
    shadows: shadows,
  ),
);

skir.PresentationNode _sized(
  String id,
  double width,
  double height,
  skir.PresentationNode child,
) => presentationNode(
  id,
  skir.PresentationElement.createSize(
    child: child,
    width: numberLiteral(width),
    height: numberLiteral(height),
    minimumWidth: null,
    maximumWidth: null,
    minimumHeight: null,
    maximumHeight: null,
  ),
);

/// A row of the paint primitives: a stacked volume whose page edges fan out
/// on selection behind a cover that tilts open, a card that lifts on hover
/// with a shadow that grows on focus, and adjusted color swatches.
final paintPrimitivesNode = presentationNode(
  "paint",
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createRow(
      children: [
        skir.AxisChild.wrapFixed(_volume),
        skir.AxisChild.wrapFixed(_liftingCard),
        skir.AxisChild.wrapFixed(_swatches),
      ],
      layout: skir.AxisChildrenLayout(
        spacing: 40,
        mainAxisAlignment: skir.MainAxisAlignment.center,
        crossAxisAlignment: skir.CrossAxisAlignment.center,
        clipOverflow: false,
      ),
    ),
  ),
);

final _volume = _sized(
  "volume",
  175,
  230,
  presentationNode(
    "volume.stack",
    skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createStack(
        alignment: null,
        children: [
          for (final (index, (rest, raised, end, endRaised, lightness))
              in const [
                (10.0, 15.0, 0.0, 0.0, -0.3),
                (5.0, 12.0, 5.0, 4.0, -0.1),
                (5.0, 10.0, 5.0, 8.0, 0.0),
                (5.0, 5.0, 5.0, 14.0, 0.1),
              ].indexed)
            skir.StackChild.createPositioned(
              child: _surface(
                "volume.edge.$index",
                color: skir.PresentationColor.createBrightness(
                  light: skir.PresentationColor.createAdjusted(
                    source: _literal(_accent),
                    lightness: lightness + 0.4,
                    chroma: -0.3,
                  ),
                  dark: skir.PresentationColor.createAdjusted(
                    source: _literal(_accent),
                    lightness: lightness,
                    chroma: -0.3,
                  ),
                ),
              ),
              top: _when(_selected, rest, raised),
              start: null,
              end: _when(_selected, end, endRaised),
              bottom: _when(_selected, rest, raised),
              width: _number(30),
              height: null,
              transition: _selectMotion,
            ),
          skir.StackChild.createPositioned(
            child: presentationNode(
              "volume.cover",
              skir.PresentationElement.createTransform(
                child: _surface(
                  "volume.cover.surface",
                  color: _literal(_accent),
                  child: presentationNode(
                    "volume.cover.padding",
                    skir.PresentationElement.createPadding(
                      child: presentationText(
                        "volume.title",
                        textLiteral("Main story"),
                      ),
                      top: 12,
                      start: 24,
                      end: 12,
                      bottom: 12,
                    ),
                  ),
                ),
                origin: skir.PresentationAlignment.centerStart,
                perspective: 0.002,
                scale: _when(_selected, 1, 0.9),
                rotateX: null,
                rotateY: _when(_selected, 0, 0.05),
                rotateZ: null,
                translateX: null,
                translateY: null,
                transition: _selectMotion,
              ),
            ),
            top: _number(0),
            start: _number(0),
            end: _number(10),
            bottom: _number(0),
            width: null,
            height: null,
            transition: null,
          ),
        ],
      ),
    ),
  ),
);

final _liftingCard = presentationNode(
  "lift",
  skir.PresentationElement.createTransform(
    child: _sized(
      "lift.size",
      160,
      110,
      _surface(
        "lift.surface",
        color: skir.PresentationColor.createBrightness(
          light: _literal(Colors.white),
          dark: _literal(const Color(0xff263238)),
        ),
        shadows: [
          skir.PresentationShadow(
            color: skir.PresentationColor.createStates(
              rules: [
                skir.PresentationStateColorRule(
                  match: _focused,
                  color: _literal(_accent.withValues(alpha: 0.6)),
                ),
              ],
              fallback: _literal(Colors.black.withValues(alpha: 0.25)),
            ),
            blur: 12,
            spread: 0,
            offsetX: 0,
            offsetY: 4,
          ),
        ],
        child: presentationNode(
          "lift.padding",
          skir.PresentationElement.createPadding(
            child: presentationText("lift.label", textLiteral("Hover lifts")),
            top: 16,
            start: 16,
            end: 16,
            bottom: 16,
          ),
        ),
      ),
    ),
    origin: skir.PresentationAlignment.center,
    perspective: 0,
    scale: _when(_hovered, 1, 1.05),
    rotateX: null,
    rotateY: null,
    rotateZ: _when(_hovered, 0, 0.005),
    translateX: null,
    translateY: _when(_hovered, 0, -6),
    transition: _selectMotion,
  ),
);

final _swatches = presentationNode(
  "swatches",
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [
        for (final (index, lightness) in const [
          -0.5,
          -0.2,
          0.0,
          0.2,
          0.5,
        ].indexed)
          skir.AxisChild.wrapFixed(
            _sized(
              "swatch.$index",
              80,
              24,
              _surface(
                "swatch.$index.surface",
                color: skir.PresentationColor.createAdjusted(
                  source: _literal(_accent),
                  lightness: lightness,
                  chroma: 0,
                ),
              ),
            ),
          ),
      ],
      layout: skir.AxisChildrenLayout(
        spacing: 6,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.center,
        clipOverflow: false,
      ),
    ),
  ),
);

Widget compiledBookItemGridStory({double width = 760}) => FakeApp(
  child: Material(
    child: Center(
      child: SizedBox(width: width, child: const _BookItemGrid()),
    ),
  ),
);

class _BookItemGrid extends HookWidget {
  const _BookItemGrid();

  static const _books = [
    ("Main story", 0xff3f51b5),
    ("Side quests", 0xff009688),
    ("Village life", 0xffe67e22),
    ("The long night", 0xff8e44ad),
    ("Harbor", 0xff2980b9),
    ("", 0xffc0392b),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = useState<int?>(null);
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    final catalog = useMemoized(
      () => CheckedEditorCatalog(compiledSdkControlCatalog),
    );
    final material = (catalog.selectPresentation(
      compiledSdkBookRecord.configuration,
      skir.PresentationRole.item,
    ) as SelectedEditorPresentation).material;
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 0.72,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final (title, color) = _books[index];
        final id = skir.ResourceId(value: "book:$index");
        final record = _book(title, color);
        return _BookItem(
          selected: selected.value == index,
          onSelect: () => selected.value = index,
          label: catalog.appearanceOf(record).label,
          child: PortablePresentationNodeRenderer(
            node: material.layout,
            fillAvailableSpace: true,
            scope: PortablePresentationScope(
              operations: operations,
              bindings: {
                configuredValueBindingId: PortableExpressionBinding(
                  value: skir.DataValue.createNamed(
                    actualType:
                        (record.configuration
                                as skir.TypeSelection_completeWrapper)
                            .value,
                    payload: skir.DataValue.createRecord(fields: record.fields),
                  ),
                  location: skir.ValueLocation(
                    resource: id,
                    path: editorRootPath,
                  ),
                ),
                presentationSubjectIdentifierBindingId: id
                    .toExpressionBinding(),
                presentationSubjectAppearanceBindingId: catalog
                    .appearanceOf(record)
                    .toExpressionBinding(),
              },
              budget: skir.EvaluationBudget(
                maxSteps: 10000,
                maxCollectionItems: 100,
              ),
              catalog: catalog,
              resource: id,
              role: skir.PresentationRole.item,
            ).withMaterial(material),
          ),
        );
      },
    );
  }

  static skir.AuthoringRecord _book(String title, int color) =>
      skir.AuthoringRecord(
        configuration: compiledSdkBookRecord.configuration,
        fields: [
          for (final field in compiledSdkBookRecord.fields)
            switch (field.name) {
              "title" => skir.FieldValue(
                name: "title",
                value: skir.DataValue.wrapStringValue(title),
              ),
              "color" => skir.FieldValue(
                name: "color",
                value: colorValue(color),
              ),
              _ => field,
            },
        ],
      );
}

/// A focusable volume that publishes hover, focus and selection to its
/// presentation, as the resources host does in the Library.
class _BookItem extends HookWidget {
  const _BookItem({
    required this.selected,
    required this.onSelect,
    required this.label,
    required this.child,
  });

  final bool selected;
  final VoidCallback onSelect;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);
    final focused = useState(false);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => hovered.value = value,
        onShowFocusHighlight: (value) => focused.value = value,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onSelect();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSelect,
          child: PresentationInteractionScope(
            value: PresentationInteraction(
              hovered: hovered.value,
              focused: focused.value,
              selected: selected,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
