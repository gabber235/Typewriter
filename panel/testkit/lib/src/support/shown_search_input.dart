import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/doubles/presentation_host.dart";
import "package:typewriter_testkit/src/doubles/projecting_host.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";

/// A search over the static [choices], keyed by item id, that writes the
/// chosen one to [target].
///
/// Results bind as [resultType] (text unless given) and show their value.
/// A [listType] collects several choices into that list type; otherwise one
/// choice replaces the value. The search is labeled [label], shows
/// [placeholder] and [summary] when given, and grows to [maximumExtent].
skir.SearchControl staticSearchControl({
  required skir.BindingRef target,
  required Map<String, skir.DataValue> choices,
  skir.TypeTemplate? resultType,
  skir.TypeDefinitionId? listType,
  String? label,
  String? placeholder,
  skir.PresentationNode? summary,
  double maximumExtent = 220,
}) {
  final row = skir.ExpressionBindingId(value: "row");
  final rowRead = inputExpression(row);
  final control = skir.SearchControl.mutable()
    ..control =
        (skir.BoundControl.mutable()
              ..binding = target
              ..label = label == null ? null : textLiteral(label))
            .toFrozen()
    ..selectionMode = listType == null
        ? skir.SearchSelectionMode.single
        : skir.SearchSelectionMode.multiple
    ..queryBinding = declareNamedBinding("query", textTemplate)
    ..summaryBinding = declareNamedBinding(
      "summary",
      listType == null
          ? textTemplate
          : skir.TypeTemplate.createNamed(
              definition: listType,
              arguments: const [],
            ),
    )
    ..maximumExtent = numberLiteral(maximumExtent)
    ..placeholder = placeholder == null ? null : textLiteral(placeholder)
    ..provider = skir.SearchProvider.createStaticValues(
      values: literalExpression(
        skir.DataValue.createListValue(
          items: [
            for (final choice in choices.entries)
              skir.ListItem(
                id: skir.ItemId(value: choice.key),
                value: choice.value,
              ),
          ],
        ),
      ),
      result: skir.SearchResultMapping(
        binding: declareBinding(row, resultType ?? textTemplate),
        key: rowRead,
        selectedValue: rowRead,
        label: rowRead,
        presentation: presentationText("result", rowRead),
      ),
      selectors: const [],
    );
  if (summary != null) control.summary = summary;
  return control.toFrozen();
}

/// Shows a search over Alpha and Beta that writes the root of the value
/// holding [value], Alpha by default, reporting each write to [onWrite] and
/// reaching remote sources through [client] when given.
Future<PanelDriver> showAlphaBetaSearch(
  WidgetTester tester, {
  String value = "Alpha",
  void Function(skir.DataValue value)? onWrite,
  Client? client,
}) {
  final target = skir.ExpressionBindingId(value: "target");
  return tester.showComponent(
    Scaffold(
      body: PortableSearchInput(
        control: staticSearchControl(
          target: skir.BindingRef(bindingId: target, path: editorRootPath),
          maximumExtent: 240,
          choices: {
            for (final choice in const ["Alpha", "Beta"])
              choice.toLowerCase(): skir.DataValue.wrapStringValue(choice),
          },
          summary: presentationText(
            "summary",
            inputExpression(skir.ExpressionBindingId(value: "summary")),
          ),
        ),
        scope: PortablePresentationScope(
          operations: testPortableOperations(),
          bindings: {
            target: PortableExpressionBinding(
              value: skir.DataValue.wrapStringValue(value),
            ),
          },
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          host: FakePresentationHost(
            document: FakePresentationHost.emptyDocument(
              catalog: CheckedEditorCatalog(
                testCatalogSnapshot(
                  generation: skir.CatalogGeneration(value: "catalog:static"),
                ),
              ),
            ),
            value: skir.DataValue.wrapStringValue(value),
            onWrite: onWrite == null ? null : (_, written) => onWrite(written),
          ),
        ),
        client: client,
      ),
    ),
  );
}

/// Projects [resource] with an appearance named after its id.
PortableResourceProjection namedResourceProjection(skir.ResourceId resource) =>
    PortableResourceProjection(
      resource: resource,
      configuration: skir.TypeSelection.unknown,
      appearance: skir.ResourceAppearance(
        label: "Resource ${resource.value.split(":").last}",
        accent: const Color(0xff607d8b).toSkirColor(),
        icon: skir.Icon.wrapIconify("material-symbols:category"),
      ),
      value: skir.DataValue.unfilled,
    );

/// One search input over a text value holding "Book", offering Book, Map
/// and Star, whose host keeps every applied write.
final class SearchInputScenario {
  SearchInputScenario({
    this.readOnly = false,
    this.reject = false,
    this.rebuildDuringWrite = false,
    this.resources = false,
  });

  /// Offers links to resources the host projects, instead of text values.
  final bool resources;

  /// Whether every write is refused as unavailable.
  final bool reject;

  /// Whether a write rebuilds the owner and takes 40 milliseconds.
  final bool rebuildDuringWrite;

  /// Whether the input is read only.
  final bool readOnly;

  /// Tells the presentation the value changed.
  final owner = ValueNotifier(0);

  /// The current value.
  skir.DataValue value = skir.DataValue.wrapStringValue("Book");

  /// Every applied write, in order.
  final writes = <skir.DataValue>[];

  /// The binding the search writes.
  static final target = skir.ExpressionBindingId(value: "target");

  /// The search control shown; a test may replace it before showing.
  late skir.SearchControl control = staticSearchControl(
    target: skir.BindingRef(bindingId: target, path: editorRootPath),
    label: "Icon identifier",
    placeholder: "Search icons",
    resultType: resources ? skir.TypeTemplate.unknown : null,
    choices: {
      for (final name in ["Book", "Map", "Star"])
        name: resources
            ? skir.DataValue.createLink(
                endpoint: skir.EndpointId(value: "test.result"),
                target: skir.LinkTarget(
                  resource: skir.ResourceId(value: "resource:$name"),
                  opposite: null,
                ),
              )
            : skir.DataValue.wrapStringValue(name),
    },
  );

  /// Shows the search [width] wide above a following button, through
  /// [ShowComponent.showComponent].
  Future<PanelDriver> show(WidgetTester tester, {double width = 360}) async {
    final host = BoundPresentationHost(
      readOnly: readOnly,
      catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
      root: () => presentationNode(
        "search",
        skir.PresentationElement.wrapSearchInput(control),
      ),
      bindings: [
        BoundPresentationBinding(
          id: target,
          use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          owner: owner,
          read: (_) => value,
          write: (_, next) async {
            if (reject) {
              return PortablePresentationWriteResult.rejected([
                const PortablePresentationDiagnostic(
                  code: "unavailable",
                  message: "Selection is unavailable",
                  severity: skir.DiagnosticSeverity.error,
                ),
              ]);
            }
            writes.add(next);
            value = next;
            if (rebuildDuringWrite) {
              owner.value++;
              await Future<void>.delayed(const Duration(milliseconds: 40));
            }
            return const PortablePresentationWriteApplied();
          },
        ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    );
    addTearDown(host.dispose);
    addTearDown(owner.dispose);
    return tester.showComponent(
      Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortablePresentationRenderer(
                  host: resources
                      ? ProjectingHost(host, resources: namedResourceProjection)
                      : host,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("Following field"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
