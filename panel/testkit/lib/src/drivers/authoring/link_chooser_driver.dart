import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/realm_world.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/core/test_world.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/finders.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/src/traits/authoring/realm.dart";

/// A link control and the link target chooser it opens: the author opens
/// the chooser, picks a target resource with the counterpart it should get,
/// and saves the edit to the Realm.
final class LinkChooserDriver extends ComponentDriver {
  LinkChooserDriver._(super.tester, this.world, this.binding);

  /// The world serving the Realm the link is edited in.
  final World world;

  /// The open editing of the resource holding the link.
  final RealmEditingBinding binding;

  /// Serves [document] in a Realm, opens editing of the resource holding
  /// [source] and shows the link control of [source], [readOnly] or not,
  /// preparing new counterparts through [prepareValue]. The control's link
  /// field builder is [linkFieldBuilder] when given.
  static Future<LinkChooserDriver> show(
    WidgetTester tester,
    AuthoringDocument document, {
    required skir.ValueLocation source,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
    prepareValue,
    Widget Function(BuildContext, skir.ValueLocation, Widget)? linkFieldBuilder,
    bool readOnly = false,
  }) async {
    final world = testWorld(adaServing(document));
    await tester.pumpWidget(
      PanelStage.world(world, at: const PanelLocation.component(SizedBox())),
    );
    final opening = world.openRealmEditing();
    await tester.pumpAndSettle();
    final binding = (await opening).form(source.resource);
    final root = skir.ExpressionBindingId(value: "configured_value");
    final budget = skir.EvaluationBudget(
      maxSteps: 100,
      maxCollectionItems: 100,
    );
    final host = AuthoredPresentationHost(
      resource: source.resource,
      source: binding.document,
      material: skir.PresentationMaterial.defaultInstance,
      role: skir.PresentationRole.workspace,
      budget: budget,
      capabilities: const PortablePresentationCapabilities(),
      prepareValue: prepareValue,
      edit: binding,
    );
    addTearDown(host.dispose);
    await tester.pumpWidget(
      PanelStage.world(
        world,
        at: PanelLocation.component(
          Scaffold(
            body: PortableResourcesInteractionScope(
              itemBuilder: (context, view, member, child) => child,
              layoutBuilder: (context, view, child) => child,
              linkFieldBuilder: linkFieldBuilder,
              child: PortablePresentationNodeRenderer(
                node: skir.PresentationNode(
                  nodeId: "link",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: skir.PresentationElement.wrapLinkInput(
                    skir.LinkControl(
                      control: skir.BoundControl(
                        binding: skir.BindingRef(
                          bindingId: root,
                          path: source.path,
                        ),
                        label: null,
                        description: null,
                        prefix: null,
                        semanticLabel: null,
                      ),
                      allowReorder: false,
                      candidatePolicy: null,
                      rejectionDisplay: skir.LinkRejectionDisplay.disabled,
                      sourceId: null,
                      appearance: null,
                      content: null,
                      inputAppearance: null,
                      inputContent: null,
                      popup: null,
                    ),
                  ),
                  header: null,
                ),
                scope: PortablePresentationScope(
                  operations: testPortableOperations(),
                  bindings: {
                    root: PortableExpressionBinding(
                      value: skir.DataValue.createRecord(
                        fields: document.resource(source.resource)!.fields,
                      ),
                      location: skir.ValueLocation(
                        resource: source.resource,
                        path: skir.ValuePath(segments: const []),
                      ),
                    ),
                  },
                  budget: budget,
                  catalog: document.catalog,
                  host: host,
                  readOnly: readOnly,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return LinkChooserDriver._(tester, world, binding);
  }

  /// Opens the chooser through the control's button [tooltip].
  Future<void> open({String tooltip = "Choose linked resource"}) async {
    await tester.tap(find.tooltip(tooltip));
    await tester.pumpAndSettle();
  }

  /// Closes the open chooser without choosing.
  Future<void> close() async {
    await tester.tap(find.tooltip("Close"));
    await tester.pumpAndSettle();
  }

  /// The chooser row that links [target] with the counterpart [choice],
  /// found by what it announces.
  Finder choice(skir.ResourceId target, String choice) => find.bySemanticsLabel(
    RegExp("^${RegExp.escape(target.value)}: ${RegExp.escape(choice)}"),
  );

  /// Chooses [target] with the counterpart [counterpart].
  Future<void> choose(skir.ResourceId target, String counterpart) async {
    await tester.tap(choice(target, counterpart));
    await tester.pumpAndSettle();
  }

  /// Saves the edit and returns the Realm's saved document.
  Future<AuthoringDocument> save() async {
    final saving = binding.save();
    await tester.pumpAndSettle();
    await saving;
    await tester.pump();
    return world.requireRealm.document;
  }
}
