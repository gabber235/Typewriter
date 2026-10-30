import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/doubles/presentation_host.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/src/shared/editors/presentation/collection_editor_fixture.dart";
import "package:typewriter_testkit/src/shared/editors/presentation/value_inspector_fixture.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";

/// A binding over one whole value: [read] gives it and every write replaces
/// it through [write], whatever path the presentation edits.
BoundPresentationBinding wholeValueBinding(
  skir.ExpressionBindingId id,
  skir.TypeUse use, {
  required skir.DataValue Function() read,
  required void Function(skir.DataValue value) write,
}) => BoundPresentationBinding(
  id: id,
  use: use,
  read: (_) => read(),
  write: (_, next) {
    write(next);
    return const PortablePresentationWriteApplied();
  },
);

/// A 64 bit float.
final float64 = skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour);

/// A number input over the float binding [binding] that shows its value
/// with two decimals in US English outside editing and, when [rounded],
/// completes typing to the nearest half, ties to even.
skir.NumericControl formattedNumberControl(
  skir.ExpressionBindingId binding, {
  bool rounded = false,
}) {
  final candidate = skir.ExpressionBindingId(value: "candidate");
  final read = skir.ExpressionNode.createInput(
    binding: candidate,
    path: editorRootPath,
  );
  skir.ExpressionMapping mapping(skir.ExpressionNode body) =>
      skir.ExpressionMapping(
        inputBinding: declareBinding(candidate, scalarTemplate(float64)),
        body: body,
      );
  return (skir.NumericControl.mutable()
        ..control = (skir.BoundControl.mutable()
          ..binding = skir.BindingRef(bindingId: binding, path: editorRootPath))
        ..mappings = skir.ValueMappings(
          completion: rounded
              ? mapping(
                  portableCall("number.round", [
                    read,
                    literalExpression(skir.DataValue.wrapFloat(0.5)),
                    skir.ExpressionNode.wrapLiteral(
                      skir.RoundingMode.nearestTiesToEven.toDataValue(),
                    ),
                  ]),
                )
              : null,
          display: mapping(
            portableCall("number.format", [
              read,
              literalExpression(skir.DataValue.wrapInteger("2")),
              textLiteral("en-US"),
            ]),
          ),
        ))
      .toFrozen();
}

/// Showing an authored presentation in the panel.
extension ShowPresentation on WidgetTester {
  /// Shows the presentation [root] builds over [bindings], typed by
  /// [catalog] or by an empty catalog, through [showComponent].
  ///
  /// The host lives until the test ends.
  Future<PanelDriver> showPresentation(
    skir.PresentationNode Function() root, {
    required List<BoundPresentationBinding> bindings,
    CheckedEditorCatalog? catalog,
    bool readOnly = false,
  }) {
    final host = BoundPresentationHost(
      readOnly: readOnly,
      catalog:
          catalog ?? CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
      root: root,
      bindings: bindings,
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    );
    addTearDown(host.dispose);
    return showPresentationHost(host);
  }

  /// Shows the presentation [host] renders, disposing the host when the
  /// test ends.
  Future<PanelDriver> showRenderer(PortablePresentationHost host) {
    if (host case final ChangeNotifier notifier) addTearDown(notifier.dispose);
    return showComponent(
      Material(child: PortablePresentationRenderer(host: host)),
    );
  }

  /// Shows the number input [control] over a float binding that reads
  /// [read] and keeps every value [write] receives.
  Future<PanelDriver> showNumberInput(
    skir.NumericControl control, {
    required skir.DataValue Function() read,
    required void Function(skir.DataValue value) write,
  }) => showPresentation(
    () => presentationNode(
      "numeric",
      skir.PresentationElement.wrapNumericInput(control),
    ),
    bindings: [
      wholeValueBinding(
        control.control.binding.bindingId,
        skir.TypeUse.wrapScalar(float64),
        read: read,
        write: write,
      ),
    ],
  );

  /// Shows [root] rendered in [scope] and filling [size], on a [surface] of
  /// that color when given, under a
  /// presentation interaction, and returns the function that replaces that
  /// interaction, the way pointer and focus changes do.
  Future<void Function(PresentationInteraction)> showInteractiveNode(
    skir.PresentationNode root, {
    required PortablePresentationScope scope,
    Size size = const Size(200, 260),
    Color? surface,
  }) async {
    var interaction = const PresentationInteraction();
    late StateSetter update;
    final centered = Center(
      child: SizedBox.fromSize(
        size: size,
        child: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PresentationInteractionScope(
              value: interaction,
              child: PortablePresentationNodeRenderer(
                node: root,
                scope: scope,
                fillAvailableSpace: true,
              ),
            );
          },
        ),
      ),
    );
    await showComponent(
      surface == null ? centered : Surface(color: surface, child: centered),
    );
    return (next) => update(() => interaction = next);
  }

  /// Shows [element] in a scaffold, in a scope whose [binding] holds
  /// [value], over a [FakePresentationHost] that expects [expected] or text.
  ///
  /// Every applied write goes to [onWrite]; with [rebindWrites] the scope
  /// then holds the written value, the way an owner that stores it does.
  Future<PanelDriver> showBoundElement(
    skir.PresentationElement element,
    skir.DataValue value, {
    required skir.ExpressionBindingId binding,
    ValueChanged<skir.DataValue>? onWrite,
    skir.TypeUse? expected,
    bool readOnly = false,
    bool enabled = true,
    bool rebindWrites = false,
  }) {
    var current = value;
    final operations = testPortableOperations();
    late StateSetter rebuild;
    final host = FakePresentationHost(
      expected: expected ?? skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      onWrite: (_, replacement) {
        onWrite?.call(replacement);
        if (rebindWrites) rebuild(() => current = replacement);
      },
    );
    addTearDown(host.dispose);
    return showComponent(
      StatefulBuilder(
        builder: (_, setState) {
          rebuild = setState;
          return Scaffold(
            body: PortablePresentationNodeRenderer(
              node: skir.PresentationNode(
                nodeId: "scalar",
                properties: skir.PresentationProperties.defaultInstance,
                element: element,
                header: null,
              ),
              scope: PortablePresentationScope(
                operations: operations,
                bindings: {binding: PortableExpressionBinding(value: current)},
                budget: skir.EvaluationBudget(
                  maxSteps: 100,
                  maxCollectionItems: 100,
                ),
                readOnly: readOnly,
                enabled: enabled,
                host: host,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Shows [node] rendered in [scope] in a scaffold through [showComponent].
  Future<PanelDriver> showNode(
    skir.PresentationNode node,
    PortablePresentationScope scope,
  ) => showComponent(
    Scaffold(
      body: PortablePresentationNodeRenderer(node: node, scope: scope),
    ),
  );

  /// Shows the presentation [host] holds in a scaffold through
  /// [showComponent], in a scroll view when it [scrolls]; the caller owns
  /// the host.
  Future<PanelDriver> showPresentationHost(
    PortablePresentationHost host, {
    bool scrolls = false,
  }) {
    final renderer = PortablePresentationRenderer(host: host);
    return showComponent(
      Scaffold(
        body: scrolls ? SingleChildScrollView(child: renderer) : renderer,
      ),
    );
  }
}

/// One value a shown presentation edits as a whole through the binding [id];
/// every write replaces [value] and is kept in [writes].
final class EditedValue {
  /// Holds [value] of type [use] behind the binding named [binding].
  EditedValue(this.value, this.use, {String binding = "fixture"})
    : id = skir.ExpressionBindingId(value: binding);

  /// Holds the scalar [value] of [kind] behind the binding named [binding].
  EditedValue.scalar(
    skir.DataValue value,
    skir.ScalarKind kind, {
    String binding = "fixture",
  }) : this(value, skir.TypeUse.wrapScalar(kind), binding: binding);

  /// The current value.
  skir.DataValue value;

  /// The type the binding declares.
  final skir.TypeUse use;

  /// The binding the presentation reads and writes.
  final skir.ExpressionBindingId id;

  /// Every value written, in order.
  final writes = <skir.DataValue>[];

  /// The whole value, as a control binds it.
  skir.BindingRef get reference =>
      skir.BindingRef(bindingId: id, path: editorRootPath);

  /// A control over the whole value with no label.
  skir.BoundControl get control =>
      (skir.BoundControl.mutable()..binding = reference).toFrozen();

  /// The presentation binding over the value.
  BoundPresentationBinding get binding => wholeValueBinding(
    id,
    use,
    read: () => value,
    write: (next) {
      writes.add(next);
      value = next;
    },
  );

  /// Shows [element] over the value through [ShowPresentation.showPresentation].
  Future<PanelDriver> show(
    WidgetTester tester,
    skir.PresentationElement element, {
    bool readOnly = false,
    CheckedEditorCatalog? catalog,
  }) => tester.showPresentation(
    () =>
        (skir.PresentationNode.mutable()
              ..nodeId = "fixture"
              ..element = element)
            .toFrozen(),
    bindings: [binding],
    readOnly: readOnly,
    catalog: catalog,
  );
}

/// Showing a value inspector in the panel.
extension ShowValueInspector on ValueInspector {
  /// Pumps a fresh panel that shows the inspector in a scroll view; the host
  /// lives until the test ends.
  Future<PanelDriver> show(WidgetTester tester) {
    final host = this.host();
    addTearDown(host.dispose);
    return tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SingleChildScrollView(child: PortablePresentationRenderer(host: host)),
      ),
    );
  }
}

/// What surrounds a shown collection editor, changed while a test runs.
///
/// The stage lives until the test ends.
final class CollectionEditorStage extends ChangeNotifier {
  CollectionEditorStage({this.host, this.width = 640}) {
    addTearDown(dispose);
  }

  /// The width the collection gets.
  double width;

  /// The host the collection renders; null renders the scenario's own.
  PortablePresentationHost? host;

  /// The page shown instead of the collection once the user moved on.
  Widget? next;

  /// Applies [update] and rebuilds what the stage surrounds.
  void change(VoidCallback update) {
    update();
    notifyListeners();
  }
}

/// Showing a collection editor scenario in the panel.
extension ShowCollectionEditor on CollectionEditorScenario {
  /// Pumps the collection behind a [GatedRemovalHost] that holds every list
  /// item removal until the returned gate answers, then waits for
  /// [settlement] when given. The stage starts with the gated host.
  Future<
    ({
      PanelDriver panel,
      Completer<bool> gate,
      GatedRemovalHost host,
      CollectionEditorStage stage,
    })
  >
  showGated(WidgetTester tester, {Completer<void>? settlement}) async {
    final gate = Completer<bool>();
    final gated = GatedRemovalHost(host, gate, settlement: settlement);
    addTearDown(gated.dispose);
    final stage = CollectionEditorStage(host: gated);
    final panel = await show(tester, stage: stage);
    return (panel: panel, gate: gate, host: gated, stage: stage);
  }

  /// Pumps a fresh panel that shows the collection in a scroll view, inside
  /// [stage] or a default one.
  Future<PanelDriver> show(
    WidgetTester tester, {
    bool readOnly = false,
    CollectionEditorStage? stage,
  }) {
    final shown = stage ?? CollectionEditorStage();
    return tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ListenableBuilder(
          listenable: shown,
          builder: (context, _) =>
              shown.next ??
              SingleChildScrollView(
                child: SizedBox(
                  width: shown.width,
                  child: CollectionEditorScenarioView(
                    scenario: this,
                    readOnly: readOnly,
                    host: shown.host,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

/// Matches a presentation write the host refused for exactly the one
/// [reason] the author reads.
Matcher writeRejectedBecause(String reason) =>
    isA<PortablePresentationWriteRejected>().having(
      (rejected) => [
        for (final diagnostic in rejected.diagnostics) diagnostic.message,
      ],
      "reasons",
      [reason],
    );
