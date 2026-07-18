import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/shared/search/presentation/search_root.dart";
import "package:typewriter_panel/shared/search/search_engine.dart";
import "package:typewriter_panel/shared/ui/components/elastic_switcher.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/shared/utilities/adaptive_single_activator.dart";

class SearchShortcuts extends HookConsumerWidget {
  const SearchShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final currentPreview = controller.currentPreview;

    final actionState = controller.actionState;
    final actionsBusy = actionState is SearchActionRunning;

    final List<ActionShortcut> shortcuts;
    if (currentPreview == null) {
      shortcuts = [];
    } else {
      final actions = controller.actionsFor(currentPreview);
      final actionResults = switch (actionState) {
        SearchActionIdle() => null,
        SearchActionRunning(:final resultIds) => resultIds,
        SearchActionCompleted(:final resultIds) => resultIds,
        SearchActionFailed(:final resultIds) => resultIds,
      };
      final actionConcersThis =
          actionResults?.contains(currentPreview.id) ?? false;

      void execute(Type actionType) {
        controller.executeAction(actionType, resultId: currentPreview.id);
      }

      Widget? actionIcon(SearchAction action) {
        if (actionConcersThis &&
            actionsBusy &&
            actionState.action == action.runtimeType) {
          return Builder(
            builder: (context) {
              final iconTheme = IconTheme.of(context);
              final iconSize = iconTheme.size ?? 24.0;
              final color = iconTheme.color;
              return SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2,
                  padding: const EdgeInsets.all(2),
                ),
              );
            },
          );
        }
        if (action.icon != null) {
          return Icones(action.icon!);
        }
        return null;
      }

      shortcuts = [
        for (final action in actions) ...[
          ActionShortcut(
            id: "search_result_${currentPreview.id}_${action.runtimeType}",
            label: action.label,
            icon: ElasticSwitcher(child: actionIcon(action)),
            description: "",
            activators: [?action.shortcut],
            priority: action.priority,
            onInvoke: actionsBusy ? null : (_) => execute(action.runtimeType),
          ),

          // Selection
          ActionShortcut(
            id: "search_result_${currentPreview.id}_select",
            label: controller.isSelected(currentPreview.id)
                ? "Deselect"
                : "Select",
            description: "Toggle selection for this result",
            activators: [SingleActivator(LogicalKeyboardKey.space)],
            priority: 0,
            onInvoke: (_) => controller.toggleSelected(currentPreview.id),
          ),
        ],
      ];
    }

    final fastLinks = controller.snapshot.nodes
        .walk()
        .whereType<SearchResultNode>()
        .map((node) => node.result)
        .take(9)
        .indexed
        .map((e) {
          final (index, result) = e;
          final primaryActionType = result.actions.firstOrNull;
          if (primaryActionType == null) return null;
          final primaryAction = controller.snapshot.actions[primaryActionType];
          if (primaryAction == null) return null;
          return ActionShortcut(
            id: "search_result_${result.id}_$primaryActionType",
            label: primaryAction.label,
            description: "",
            activators: [
              AdaptiveSingleActivator(
                LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + index),
                control: true,
              ),
              AdaptiveSingleActivator(
                LogicalKeyboardKey(LogicalKeyboardKey.numpad1.keyId + index),
                control: true,
              ),
            ],
            priority: primaryAction.priority,
            show: false,
            onInvoke: actionsBusy
                ? null
                : (_) => controller.executeAction(
                    primaryActionType,
                    resultId: result.id,
                  ),
          );
        })
        .nonNulls
        .toList();

    shortcuts.addAll(fastLinks);

    return ManagedActionSet(shortcuts: shortcuts, child: child);
  }
}
