import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Hosts tag creation and the projected inheritance graph.
///
/// Creation prepares authored defaults, commits the unfinished resource, then
/// opens its normal inspector. Existing tags are rendered by [TagGraph], which
/// handles placement gestures through the same authoring session.
@RoutePage()
class TagsPage extends HookConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    final tagsAsync = ref.watch(workingTagsProvider);
    final viewportCenter = useRef<Offset?>(null);
    final document = ref.watch(selectedWorkingAuthoringDocumentProvider).value;
    final definitionId = coreTagResourceDefinition;
    final definition = document?.catalog.snapshot.resourceDefinitions
        .where((candidate) => candidate.id == definitionId)
        .firstOrNull;
    final selection = definition == null
        ? null
        : document?.catalog.beginSelection(definition.root);
    final canCreate =
        scope != null &&
        selection != null &&
        selection != skir.TypeSelection.unknown;

    Future<void> handleCreateTag() async {
      final current = definition == null
          ? null
          : ref
                .read(selectedWorkingAuthoringDocumentProvider)
                .value
                ?.catalog
                .beginSelection(definition.root);
      if (current == null || current == skir.TypeSelection.unknown) {
        throw StateError("Tag creation is unavailable");
      }
      final created = await ref
          .read(resourceCreationProvider(scope!))
          .create(
            context: context,
            request: ResourceCreationRequest(
              definition: definitionId,
              configuration: current,
            ),
          );
      if (created == null) return;
      ref
          .read(selectionProvider.notifier)
          .select(
            AuthoringResourceIdentifier.inScope(created.scope, created.id),
          );
    }

    return Pane(
      id: "tags",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: ManagedActionSet(
          shortcuts: [
            ActionShortcut(
              id: "tags.create",
              label: "Create Tag",
              description: "Create a new tag",
              activators: const [
                SingleActivator(LogicalKeyboardKey.keyN),
                SingleActivator(LogicalKeyboardKey.keyA),
                SingleActivator(LogicalKeyboardKey.numpadAdd),
              ],
              priority: 100,
              icon: const Icon(Icons.add),
              onInvoke: canCreate ? (_) => handleCreateTag() : null,
            ),
          ],
          child: FloatingButton(
            icon: const Icon(Icons.add),
            onPressed: canCreate ? handleCreateTag : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeading(
                  title: "Tags",
                  subtext: "Organize books with colored labels that match your project structure. Build nested tag groups for locations or story progress, then use them to filter large libraries.",
                ),
                Expanded(
                  child: tagsAsync(
                    name: "tags",
                    builder: (tags) {
                      if (tags.isEmpty) {
                        return EmptyScreen(
                          title: "No tags yet",
                          buttonText: "Create Tag",
                          onPressed: canCreate ? handleCreateTag : null,
                        );
                      }
                      return TagGraph(
                        onViewportCenterChanged: (center) {
                          viewportCenter.value = center;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
