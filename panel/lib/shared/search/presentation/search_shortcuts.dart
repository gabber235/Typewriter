import "package:typewriter_panel/typewriter_panel.dart";

/// Adds the Control plus digit shortcuts that activate the first nine results
/// in the controller tree, including descendants of collapsed sections.
///
/// A result's commands are not here: each row offers them while it has focus.
class SearchShortcuts extends HookConsumerWidget {
  const SearchShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;

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
            run: controller.isBusy
                ? null
                : ActionRun.press((_) => controller.activate(result)),
          );
        })
        .nonNulls
        .toList();

    return ManagedActionSet(shortcuts: fastLinks, child: child);
  }
}
