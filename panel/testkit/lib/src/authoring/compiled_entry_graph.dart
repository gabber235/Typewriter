import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// Showing the compiled entries of a page the way its graph lists them.
extension CompiledEntryGraph on WidgetTester {
  /// Shows the compiled entry page of [document] as a graph of the entries
  /// it owns.
  Future<PanelDriver> showCompiledEntryGraph(AuthoringDocument document) {
    final operations = testPortableOperations();
    final budget = skir.EvaluationBudget(
      maxSteps: 10000,
      maxCollectionItems: 1000,
    );
    final host = AuthoredPresentationHost(
      resource: compiledEntryPageId,
      source: document,
      material: skir.PresentationMaterial.defaultInstance,
      role: skir.PresentationRole.workspace,
      budget: budget,
      capabilities: const PortablePresentationCapabilities(),
    );
    addTearDown(host.dispose);
    final node = skir.PresentationNode(
      nodeId: "compiled.page.graph",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.createResources(
        control:
            (skir.BoundControl.mutable()
                  ..binding = skir.BindingRef(
                    bindingId: configuredValueBindingId,
                    path: editorRootPath.field("elements"),
                  ))
                .toFrozen(),
        layout: skir.ResourcesLayout.createGraph(
          direction: skir.GraphDirection.leftToRight,
          appearance: null,
        ),
        order: null,
        itemBinding: declareNamedBinding(
          "resources.item",
          document.catalog
              .collectionItemType(
                document.catalog.valueTypeAt(
                  document.resource(compiledEntryPageId)!.configuration,
                  editorRootPath.field("elements"),
                ),
              )!
              .portableTemplate,
        ),
      ),
    );
    host.update(
      source: document,
      capabilities: const PortablePresentationCapabilities(),
      available: true,
      readOnly: false,
    );
    return pumpPanel(
      const [],
      at: PanelLocation.component(
        PortablePresentationNodeRenderer(
          node: node,
          scope: PortablePresentationScope(
            operations: operations,
            bindings: {
              configuredValueBindingId: PortableExpressionBinding(
                value: skir.DataValue.createRecord(
                  fields: document.resource(compiledEntryPageId)!.fields,
                ),
                location: skir.ValueLocation(
                  resource: compiledEntryPageId,
                  path: editorRootPath,
                ),
              ),
            },
            budget: budget,
            catalog: document.catalog,
            queries: PortableExpressionQueries(
              catalog: document.catalog,
              authored: document,
            ),
            host: host,
            resource: compiledEntryPageId,
            role: skir.PresentationRole.workspace,
          ),
        ),
      ),
    );
  }
}
