import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Owned entry nodes", type: AuthoredGraphItem)
Widget authoredGraphItemStory(BuildContext context) {
  final narrow = context.knobs.boolean(
    label: "Narrow nodes",
    initialValue: false,
  );
  final readOnly = context.knobs.boolean(
    label: "Read only",
    initialValue: false,
  );
  return compiledEntryGraphStory(narrow: narrow, readOnly: readOnly);
}

Widget compiledEntryGraphStory({
  bool narrow = false,
  bool readOnly = false,
}) => AuthoringFixtureApp(
  overrides: [
    realmInteractionProvider.overrideWithValue(
      const RealmInteractionState(connectionState: RealmConnectionState.online),
    ),
    resourceIssuesProvider.overrideWith((ref, scope) {
      final document = ref.watch(workingAuthoringDocumentProvider(scope));
      return document.mapUnready<ResourceIssues>() ??
          AsyncData(ResourceIssues.evaluate(document: document.requireValue));
    }),
  ],
  scenario: narrow,
  createDocument: () =>
      compiledEntryNodeDocument(narrow: narrow, graphEditor: true),
  child: CompiledEntryGraphScene(readOnly: readOnly),
);

/// Keeps the real page host, node presentation and sidebar transfer mounted.
class CompiledEntryGraphScene extends HookConsumerWidget {
  const CompiledEntryGraphScene({
    this.readOnly = false,
    this.dropEnabled = true,
    super.key,
  });
  final bool readOnly;

  /// Whether the Village evening sidebar entry accepts dropped entry nodes.
  final bool dropEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider)!;
    final workspace = ref.watch(realmEditingProvider(scope));
    useListenable(workspace);
    final binding = useMemoized(
      () => workspace.attach(
        compiledEntryPageId,
        policy: EditorCommitPolicy.applyResource,
      ),
      [workspace],
    );
    useEffect(() => binding.detach, [binding]);
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Select with click or Enter. Use Shift and click for multiple selection. "
              "Use Shift+M and arrows to move, Shift+R and arrows to resize, Escape to leave either mode. "
              "Open the keyboard context menu for page actions, or drag onto Village evening.",
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  child: ResourceDropTarget.at(
                    scope: scope,
                    destination: DropDestination.resource(
                      compiledEntryDestinationId,
                    ),
                    canMutate: () =>
                        dropEnabled && !readOnly && workspace.state.available,
                    builder: (context, hover) => ResourceDropHighlight(
                      hover: hover,
                      child: const ListTile(
                        key: ValueKey("story.destination"),
                        title: Text("Village evening"),
                        leading: Icon(Icons.article_outlined),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // Match the live page route's overlay confined to the editor.
                  child: Navigator(
                    onDidRemovePage: (_) {},
                    pages: [
                      MaterialPage<void>(
                        child: AuthoredResourceEditor(
                          resource: compiledEntryPageId,
                          document: workspace.document,
                          edit: binding,
                          role: skir.PresentationRole.inspector,
                          budget: skir.EvaluationBudget(
                            maxSteps: 10000,
                            maxCollectionItems: 1000,
                          ),
                          readOnly: readOnly,
                          fillAvailableSpace: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
