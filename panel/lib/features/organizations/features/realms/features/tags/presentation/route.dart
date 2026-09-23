import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Hosts tag creation and the projected inheritance graph.
///
/// Creation starts from a validated identifier dialog, submits through
/// [CanonicalTags], then selects the returned resource only after persistence
/// succeeds. Existing tags are rendered by [TagGraph], which handles placement
/// gestures through the same provider.
@RoutePage()
class TagsPage extends HookConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(projectedTagsProvider);
    final viewportCenter = useRef<Offset?>(null);
    final catalogRequest = RealmEditorCatalogRequest(
      types: {referenceResourceTypes.tag},
    );
    final catalogState = ref.watch(realmCatalogProvider(catalogRequest));
    final canCreate =
        catalogState.currentCatalog
            ?.creatableRoots(CoreResourceDefinitionIds.tag)
            .singleOrNull !=
        null;

    Future<void> handleCreateTag() async {
      final tags = tagsAsync.value ?? const <Tag>[];
      final catalog = ref
          .read(realmCatalogProvider(catalogRequest))
          .requireCurrentCatalog();
      final root = catalog
          .creatableRoots(CoreResourceDefinitionIds.tag)
          .singleOrNull;
      if (root == null) throw StateError("Tag creation is unavailable");
      final created = await ref
          .read(resourceCreationProvider)
          .create(
            context: context,
            request: ResourceCreationRequest(
              definition: CoreResourceDefinitionIds.tag,
              title: "Create Tag",
              concreteRoot: root,
              partial: tagCreationPartial(
                tags,
                preferredGraphAnchor: viewportCenter.value,
              ),
            ),
          );
      if (created == null) return;
      ref.read(selectionProvider.notifier).select(TagIdentifier(created.id));
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
