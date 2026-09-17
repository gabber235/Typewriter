import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Hosts tag creation and the projected inheritance graph.
///
/// Creation starts from a validated identifier dialog, submits through
/// [CanonicalTags], then selects the returned resource only after persistence
/// succeeds. Existing tags are rendered by [TagGraph], which handles layout
/// gestures through the same provider.
@RoutePage()
class TagsPage extends HookConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(projectedTagsProvider);
    final viewportCenter = useRef<Offset?>(null);

    Future<void> handleCreateTag() async {
      final name = await _showTagNameDialog(context);
      if (name == null || name.isEmpty) return;
      final newTag = await ref
          .read(canonicalTagsProvider.notifier)
          .createTag(name: name, preferredGraphAnchor: viewportCenter.value);
      ref.read(selectionProvider.notifier).select(TagIdentifier(newTag.tagId));
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
              onInvoke: (_) => handleCreateTag(),
            ),
          ],
          child: FloatingButton(
            icon: const Icon(Icons.add),
            onPressed: handleCreateTag,
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
                          onPressed: handleCreateTag,
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

  /// Collects an identifier compatible with the inspector's name field.
  ///
  /// Cancellation and invalid submission return null. The route owns only this
  /// transient dialog value; canonical creation remains in the application
  /// provider.
  Future<String?> _showTagNameDialog(BuildContext context) async {
    return showAdvancedDialog<String>(
      context: context,
      builder: (context) {
        return HookConsumer(
          builder: (context, ref, child) {
            final controller = useTextEditingController();
            final isValid = useListenableSelector(
              controller,
              () => controller.text.isValidIdentifier,
            );
            final focusNode = useFocusNode();

            return AlertDialog(
              title: const Text("Create Tag"),
              content: EditorTextField(
                focusNode: focusNode,
                controller: controller,
                autofocus: EditorTextFieldAutoFocus.textField,
                decoration: const InputDecoration(hintText: "Enter tag name"),
                inputFormatters: identifierInputFormats.toTextInputFormatters(),
                onSubmitted: (value) {
                  if (!isValid) return;
                  Navigator.of(context).pop(value);
                },
              ),
              actions: [
                TextButton.icon(
                  icon: const Icones(Fa6Solid.xmark),
                  label: const Text("Cancel"),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                LoadingButton.filledIcon(
                  onPressed: isValid
                      ? () => Navigator.of(context).pop(controller.text)
                      : null,
                  label: const Text("Create"),
                  icon: const Icon(Icons.add),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
