import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

const _accent = Color(0xffe74c3c);
final _resource = skir.ResourceId(value: "entry:compiled");

void main() {
  testWidgets(
    "owned graph reads local names and gives concrete providers the full surface",
    (tester) async {
      var document = compiledEntryNodeDocument();
      final operations = testPortableOperations();
      final budget = skir.EvaluationBudget(
        maxSteps: 10000,
        maxCollectionItems: 1000,
      );
      final host = AuthoredPresentationHost(
        resource: compiledEntryPageId,
        source: document,
        material: skir.PresentationMaterial.defaultInstance,
        role: skir.PresentationRole.workspaceEditor,
        budget: budget,
        capabilities: const PortablePresentationCapabilities(),
      );
      addTearDown(host.dispose);
      final node = skir.PresentationNode(
        nodeId: "compiled.page.graph",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: skir.PresentationElement.createPageGraph(
          control:
              (skir.BoundControl.mutable()
                    ..binding = skir.BindingRef(
                      bindingId: configuredValueBindingId,
                      path: editorRootPath.field("elements"),
                    ))
                  .toFrozen(),
          direction: skir.PageGraphDirection.leftToRight,
          appearance: null,
        ),
      );
      Future<void> pump() {
        host.update(
          source: document,
          capabilities: const PortablePresentationCapabilities(),
          available: true,
          readOnly: false,
        );
        return tester.pumpTestApp(
          child: Scaffold(
            body: PortablePresentationNodeRenderer(
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
                role: skir.PresentationRole.workspaceEditor,
              ),
            ),
          ),
        );
      }

      await pump();
      expect(find.text("Welcome to the village"), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      final edit =
          AuthoringEdit(
            generation: document.generation,
            catalog: document.catalog,
            resources: document.entries.values,
            links: document.links,
          )..set(
            skir.ValueLocation(
              resource: compiledEntryFirstId,
              path: editorRootPath.field("name"),
            ),
            skir.DataValue.wrapStringValue("Local rename"),
          );
      document = edit.toDocument();
      await pump();
      expect(find.text("Local rename"), findsOneWidget);
      expect(find.text("Welcome to the village"), findsNothing);
      final selected = document.catalog.selectPresentation(
        document.resource(compiledEntryFirstId)!.configuration,
        skir.PresentationRole.editorNode,
      ) as SelectedEditorPresentation;
      final target = skir.PresentationTarget.createNamed(
        definition: compiledSdkElementValue.authoredActualType!.definition,
        arguments: const [],
      );
      final id = skir.PresentationId(namespace: "test", name: "concrete.graph");
      final material =
          (selected.material.toMutable()
                ..provider = id
                ..target = target
                ..layout = skir.PresentationNode(
                  nodeId: "concrete.surface",
                  properties: skir.PresentationProperties.defaultInstance,
                  header: null,
                  element: skir.PresentationElement.wrapText(
                    (skir.TextContent.mutable()
                          ..value = skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapStringValue("Concrete surface"),
                          ))
                        .toFrozen(),
                  ),
                ))
              .toFrozen();
      final catalog = CheckedEditorCatalog(
        (document.catalog.snapshot.toMutable()
              ..presentations = [
                ...document.catalog.snapshot.presentations,
                (selected.descriptor.toMutable()
                      ..id = id
                      ..target = target)
                    .toFrozen(),
              ]
              ..presentationMaterials = [
                ...document.catalog.snapshot.presentationMaterials,
                material,
              ])
            .toFrozen(),
      );
      document = AuthoringDocument(
        catalog: catalog,
        entries: document.entries,
        links: document.links,
      );
      await pump();
      expect(find.text("Concrete surface"), findsNWidgets(2));
      expect(find.byType(Card), findsNothing);
      expect(
        find.byWidgetPredicate((widget) => widget is PopupMenuButton),
        findsNothing,
      );
      expect(find.text("Local rename"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      "compiled entry fills its node and exposes state frames in $mode",
      (tester) async {
        final document = _document();
        Future<void> pump(PresentationInteraction state) => tester.pumpTestApp(
          themeMode: mode,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: PresentationInteractionScope(
                  value: state,
                  child: _editor(document),
                ),
              ),
            ),
          ),
        );
        await pump(const PresentationInteraction());
        expect(find.text("Compiled entry"), findsOneWidget);
        expect(find.byType(Card), findsNothing);
        expect(find.byType(PopupMenuButton<Object>), findsNothing);
        final fill = find.byWidgetPredicate(
          (widget) =>
              widget is SurfaceContainer && widget.decoration.color == _accent,
        );
        expect(fill, findsOneWidget);
        expect(tester.getSize(fill), const Size(200, 50));
        expect(_frame(tester).color, _accent);
        expect(_frame(tester).width, 3);
        final text = tester.widget<Text>(find.text("Compiled entry"));
        expect(text.style?.fontSize, 13);
        expect(text.overflow, TextOverflow.ellipsis);
        await pump(const PresentationInteraction(selected: true));
        expect(_frame(tester).color, isNot(_accent));
        final selectedColor = _frame(tester).color;
        await pump(
          const PresentationInteraction(selected: true, focused: true),
        );
        expect(_frame(tester).color, Colors.white);
        await pump(
          const PresentationInteraction(selected: true, readOnly: true),
        );
        expect(_frame(tester).color, selectedColor);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      "compiled entry adapts to a single cell and a tall node in $mode",
      (tester) async {
        // Inline SVG makes painted visibility independent of remote icon loads.
        final document = _document(
          icon: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18"><path fill="currentColor" d="M3 3h12v12H3z"/></svg>',
        );
        const boundaryKey = ValueKey("compact.node");
        for (final size in [const Size(50, 50), const Size(200, 100)]) {
          await tester.pumpTestApp(
            themeMode: mode,
            child: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox.fromSize(
                    size: size,
                    child: _editor(document),
                  ),
                ),
              ),
            ),
          );
          expect(find.byType(AdaptiveLeadingLayout), findsOneWidget);
          expect(tester.takeException(), isNull);
          final layout = tester.renderObject<RenderBox>(
            find.byType(AdaptiveLeadingLayout),
          );
          expect(layout.size.width, lessThanOrEqualTo(size.width));
          expect(layout.size.height, lessThanOrEqualTo(size.height));
          final icon = find.byType(Icones);
          expect(icon, findsOneWidget);
          expect(tester.getSize(icon), const Size(18, 18));
          final bounds = tester.getRect(find.byKey(boundaryKey));
          final frame = find.byWidgetPredicate(
            (widget) =>
                widget is SurfaceContainer && widget.decoration.border != null,
          );
          expect(tester.getRect(frame), bounds.deflate(4));
          final iconBounds = tester.getRect(icon);
          expect(iconBounds.center.dy, bounds.center.dy);
          expect(bounds.contains(iconBounds.topLeft), isTrue);
          expect(bounds.contains(iconBounds.bottomRight), isTrue);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = (await image.toByteData(
              format: ImageByteFormat.rawRgba,
            ))!;
            final local = iconBounds.shift(-bounds.topLeft);
            var inkPixels = 0;
            for (var y = local.top.ceil(); y < local.bottom.floor(); y++) {
              for (var x = local.left.ceil(); x < local.right.floor(); x++) {
                final offset = (y * image.width + x) * 4;
                if (bytes.getUint8(offset) != 231 ||
                    bytes.getUint8(offset + 1) != 76 ||
                    bytes.getUint8(offset + 2) != 60) {
                  inkPixels++;
                }
              }
            }
            image.dispose();
            expect(inkPixels, greaterThan(20));
          });
          if (size.width == 50) {
            expect(find.text("Compiled entry").hitTestable(), findsNothing);
          } else {
            expect(find.text("Compiled entry").hitTestable(), findsOneWidget);
          }
        }
      },
    );
  }
}

BorderSide _frame(WidgetTester tester) => tester
    .widgetList<SurfaceContainer>(find.byType(SurfaceContainer))
    .map((surface) => surface.decoration.border)
    .whereType<Border>()
    .single
    .top;

Widget _editor(AuthoringDocument document) => AuthoredResourceEditor(
  resource: _resource,
  document: document,
  role: skir.PresentationRole.editorNode,
  budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 1000),
  fillAvailableSpace: true,
);

AuthoringDocument _document({String? icon}) {
  var catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
  final actual = compiledSdkElementValue.authoredActualType!;
  if (icon != null) {
    catalog = CheckedEditorCatalog(
      (catalog.snapshot.toMutable()
            ..types = [
              for (final type in catalog.snapshot.types)
                if (type.definition.id == actual.definition)
                  (type.toMutable()
                        ..display = (type.display!.toMutable()..icon = icon)
                            .toFrozen())
                      .toFrozen()
                else
                  type,
            ])
          .toFrozen(),
    );
  }
  final configuration = skir.TypeSelection.wrapComplete(actual);
  final empty = AuthoringDocument(
    catalog: catalog,
    entries: const {},
    links: const [],
  );
  final elementRoot = catalog.snapshot.types
      .singleWhere(
        (type) =>
            type.definition.id.typeId ==
            skir.TypeId.createQualified(
              namespace: "kotlin",
              name: "com.typewritermc.elements.Element",
            ),
      )
      .definition
      .id;
  return AuthoringDocument(
    catalog: catalog,
    entries: {
      _resource: skir.AuthoringResource(
        id: _resource,
        definition: catalog.snapshot.resourceDefinitions
            .singleWhere((resource) => resource.root == elementRoot)
            .id,
        content: skir.AuthoringRecord(
          configuration: configuration,
          fields: [
            for (final field in catalog.fields(configuration))
              skir.FieldValue(
                name: field.template.key,
                value: field.template.key == "name"
                    ? skir.DataValue.wrapStringValue("Compiled entry")
                    : empty.defaultValue(field.type),
              ),
          ],
        ),
      ),
    },
    links: const [],
  );
}
