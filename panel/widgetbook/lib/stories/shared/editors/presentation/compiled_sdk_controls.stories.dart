import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Compiled SDK Placement",
  type: PortablePresentationRenderer,
)
Widget compiledPlacementUseCase(BuildContext context) => compiledPlacementStory(
  readOnly: context.knobs.boolean(label: "Placement read only"),
  width: context.knobs.double.slider(
    label: "Placement width",
    initialValue: 580,
    min: 320,
    max: 900,
  ),
);

@widgetbook.UseCase(name: "Compiled SDK Tag", type: AuthoredResourceEditor)
Widget compiledTagUseCase(BuildContext context) => compiledTagStory(
  width: context.knobs.double.slider(
    label: "Tag width",
    initialValue: 580,
    min: 320,
    max: 900,
  ),
);

Widget compiledPlacementStory({
  bool readOnly = false,
  double width = 580,
  ValueChanged<skir.DataValue>? onValue,
}) => FakeApp(
  child: Material(
    child: Center(
      child: SizedBox(
        width: width,
        child: _CompiledPlacement(readOnly: readOnly, onValue: onValue),
      ),
    ),
  ),
);

class _CompiledPlacement extends HookWidget {
  const _CompiledPlacement({required this.readOnly, this.onValue});
  final bool readOnly;
  final ValueChanged<skir.DataValue>? onValue;
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
                onValue?.call(nextValue);
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
    }, [readOnly, value, onValue]);
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

final compiledTagResource = skir.ResourceId(value: "tag:compiled.controls");
AuthoringDocument compiledTagDocument() {
  final root = compiledSdkTagValue.authoredActualType!.definition;
  final resourceDefinition = compiledSdkControlCatalog.resourceDefinitions
      .singleWhere((definition) => definition.root == root);
  return AuthoringEdit(
    generation: compiledSdkControlCatalog.generation,
    resources: [
      skir.AuthoringResource(
        id: compiledTagResource,
        definition: resourceDefinition.id,
        content: compiledSdkTagRecord,
      ),
    ],
    links: const [],
    catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
  ).toDocument();
}

Widget compiledTagStory({
  double width = 580,
  ValueChanged<AuthoringDocument>? onDocument,
}) => FakeApp(
  child: Center(
    child: SizedBox(
      width: width,
      height: 700,
      child: _CompiledTag(onDocument: onDocument),
    ),
  ),
);

class _CompiledTag extends StatefulWidget {
  const _CompiledTag({this.onDocument});
  final ValueChanged<AuthoringDocument>? onDocument;
  @override
  State<_CompiledTag> createState() => _CompiledTagState();
}

class _CompiledTagState extends State<_CompiledTag> {
  late final _transport = ScriptedAuthoringTransport(
    AsyncData(compiledTagDocument()),
  );
  final _submissions = ScopedWorkSession();
  late final _workspace = RealmEditing(
    persistence: _transport.persistence,
    submissions: _submissions,
    initial: compiledTagDocument(),
  );
  @override
  void initState() {
    super.initState();
    _workspace.addListener(_changed);
  }

  void _changed() => widget.onDocument?.call(_workspace.document);
  @override
  void dispose() {
    _workspace.removeListener(_changed);
    _workspace.dispose();
    _transport.dispose();
    _submissions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space4),
        child: AuthoredResourceInspection(
          resource: compiledTagResource,
          workspace: _workspace,
          commands: fixtureAuthoringCommands(_transport),
          commitPolicy: EditorCommitPolicy.applyResource,
        ),
      ),
    ),
  );
}
