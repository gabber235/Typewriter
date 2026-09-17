import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Adds keyboard commands for the current search preview and visible results.
///
/// Preview commands are exposed while a result is active. Control plus digit
/// shortcuts activate the first nine visible results.
class SearchShortcuts extends HookConsumerWidget {
  const SearchShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final currentPreview = controller.currentPreview;

    final commandState = controller.commandState;
    final commandsBusy = commandState is SearchCommandRunning;

    final List<ActionShortcut> shortcuts;
    if (currentPreview == null) {
      shortcuts = [];
    } else {
      final commands = controller.commandsFor(currentPreview);
      final commandResults = switch (commandState) {
        SearchCommandIdle() => null,
        SearchCommandRunning(:final resultIds) => resultIds,
        SearchCommandCompleted(:final resultIds) => resultIds,
        SearchCommandFailed(:final resultIds) => resultIds,
      };
      final commandConcernsThis =
          commandResults?.contains(currentPreview.id) ?? false;

      void execute(SearchCommandId commandId) {
        controller.executeCommand(commandId, resultId: currentPreview.id);
      }

      Widget? commandIcon(SearchCommand command) {
        if (commandConcernsThis &&
            commandsBusy &&
            commandState.command == command.id) {
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
        if (command.presentation.icon != null) {
          return Icones(command.presentation.icon);
        }
        return null;
      }

      shortcuts = [
        for (final resolved in commands)
          ActionShortcut(
            id: "search_result_${currentPreview.id}_${resolved.command.id.value}",
            label: resolved.command.presentation.label,
            icon: ElasticSwitcher(child: commandIcon(resolved.command)),
            description: "",
            activators: [?resolved.command.presentation.shortcut],
            priority: resolved.command.presentation.priority,
            onInvoke: commandsBusy || resolved.state is! SearchCommandEnabled
                ? null
                : (_) => execute(resolved.command.id),
          ),
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
          if (controller.activationState(result) is! SearchActivationEnabled) {
            return null;
          }
          return ActionShortcut(
            id: "search_result_${result.id}_activate",
            label: "Open ${result.title ?? result.type.label}",
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
            priority: 0,
            show: false,
            onInvoke: controller.isBusy
                ? null
                : (_) => controller.activate(result),
          );
        })
        .nonNulls
        .toList();

    shortcuts.addAll(fastLinks);

    return ManagedActionSet(shortcuts: shortcuts, child: child);
  }
}
