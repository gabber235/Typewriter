import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class TagsPage extends HookConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);

    Future<void> handleCreateTag() async {
      final name = await _showTagNameDialog(context);
      if (name == null || name.isEmpty) return;
      final newTag = await ref
          .read(tagsProvider.notifier)
          .createTag(name: name);
      ref.read(selectionProvider.notifier).select(TagIdentifier(newTag.tagId));
    }

    return Inspector(
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        right: context.spacing.space2,
      ),
      child: Pane(
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
                    subtext:
                        "Organize books with colored labels that match your project structure. Build nested tag groups for locations or story progress, then use them to filter large libraries.",
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
                        return const TagGraph();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showTagNameDialog(BuildContext context) async {
    return showAdvancedDialog<String>(
      context: context,
      builder: (context) {
        return HookConsumer(
          builder: (context, ref, child) {
            final controller = useTextEditingController();
            final isValid = useListenableSelector(
              controller,
              () => controller.text.isNotEmpty,
            );
            final focusNode = useFocusNode();

            return AlertDialog(
              title: const Text("Create Tag"),
              content: DecoratedTextField(
                focusNode: focusNode,
                controller: controller,
                autofocus: DecoratedTextFieldAutoFocus.textField,
                decoration: const InputDecoration(hintText: "Enter tag name"),
                inputFormatters: [SnakeCaseInputFormatter()],
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
                    foregroundColor: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color,
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
