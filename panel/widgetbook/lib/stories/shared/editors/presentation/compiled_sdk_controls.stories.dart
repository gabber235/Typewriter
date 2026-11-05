import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A Placement value rendered from the compiled SDK catalog, with its X and
/// Y coordinates sharing one row.
@widgetbook.UseCase(
  name: "Compiled SDK Placement",
  type: PortablePresentationRenderer,
)
Widget compiledPlacementUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    SizedBox(
      width: context.knobs.double.slider(
        label: "Placement width",
        initialValue: 580,
        min: 320,
        max: 900,
      ),
      child: _CompiledPlacement(
        readOnly: context.knobs.boolean(label: "Placement read only"),
      ),
    ),
  ),
);

/// The inspector of a Tag compiled from the SDK, with its nested Placement.
@widgetbook.UseCase(name: "Compiled SDK Tag", type: AuthoredResourceInspection)
Widget compiledTagUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    SizedBox(
      width: context.knobs.double.slider(
        label: "Tag width",
        initialValue: 580,
        min: 320,
        max: 900,
      ),
      height: 700,
      child: _CompiledInspector(
        resource: compiledTagResource,
        record: compiledSdkTagRecord,
      ),
    ),
  ),
);

/// The inspector of a Book compiled from the SDK, with its icon chosen by
/// search or written as SVG source.
@widgetbook.UseCase(name: "Compiled SDK Book", type: AuthoredResourceInspection)
Widget compiledBookUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    SizedBox(
      width: context.knobs.double.slider(
        label: "Inspector width",
        initialValue: 400,
        min: 280,
        max: 580,
      ),
      height: 760,
      child: _CompiledInspector(
        resource: compiledBookResource,
        record: compiledSdkBookRecord,
      ),
    ),
  ),
);

class _CompiledPlacement extends HookWidget {
  const _CompiledPlacement({required this.readOnly});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final value = useValueNotifier(compiledSdkPlacementValue);
    final host = useMemoized(() {
      final binding = skir.ExpressionBindingId(value: "compiled.placement");
      final reference = skir.BindingRef(
        bindingId: binding,
        path: editorRootPath,
      );
      return BoundPresentationHost(
        catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
        root: () =>
            (skir.PresentationNode.mutable()
                  ..nodeId = "compiled.placement.root"
                  ..element = skir.PresentationElement.wrapDefaultPresentation(
                    (skir.DefaultPresentationElement.mutable()
                          ..control =
                              (skir.BoundControl.mutable()..binding = reference)
                                  .toFrozen())
                        .toFrozen(),
                  ))
                .toFrozen(),
        bindings: [
          BoundPresentationBinding(
            id: binding,
            use: skir.TypeUse.wrapNamed(value.value.authoredActualType!),
            owner: value,
            read: (path) => switch (value.value.readAt(path)) {
              PortablePathValue(:final value) => value,
              PortablePathUnavailable() => null,
            },
            write: (path, next) {
              final replaced = value.value.replaceAt(path, next);
              if (replaced case PortablePathValue(value: final nextValue)) {
                value.value = nextValue;
              } else {
                return const PortablePresentationWriteRejected([]);
              }
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
        readOnly: readOnly,
        role: skir.PresentationRole.inspector,
      );
    }, [readOnly, value]);
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

final compiledTagResource = skir.ResourceId(value: "tag:compiled.controls");
final compiledBookResource = skir.ResourceId(value: "book:compiled.controls");

/// Inspects [resource] of a Realm holding only it, saving through the same
/// [RealmEditing] path a Realm surface uses.
class _CompiledInspector extends HookWidget {
  const _CompiledInspector({required this.resource, required this.record});

  final skir.ResourceId resource;
  final skir.AuthoringRecord record;

  @override
  Widget build(BuildContext context) {
    final realm = useMemoized(
      () => FakeRealm(
        scope: AuthoringScope(
          organizationId: skir.recordId("organization:story"),
          realmId: skir.recordId("realm_instance:story"),
        ),
        name: "Story",
        document: AuthoringEdit(
          generation: compiledSdkControlCatalog.generation,
          resources: [skir.AuthoringResource(id: resource, content: record)],
          links: const [],
          catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
        ).toDocument(),
      ),
    );
    final submissions = useMemoized(ScopedWorkSession.new);
    final workspace = useMemoized(
      () => RealmEditing(
        persistence: realm.persistence,
        submissions: submissions,
        initial: realm.document,
      ),
    );
    useEffect(
      () => () {
        workspace.dispose();
        submissions.dispose();
        unawaited(realm.close());
      },
      const [],
    );
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.space3),
      child: AuthoredResourceInspection(
        resource: resource,
        workspace: workspace,
        commands: realm.commands,
        commitPolicy: EditorCommitPolicy.applyResource,
      ),
    );
  }
}
