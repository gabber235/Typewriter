import "package:typewriter_panel/typewriter_panel.dart";

const _keys = [
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyB,
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyF,
];

/// The action "Action [i]" of priority [i], bound to its own letter key
/// (A, B, C, E or F for 0 to 4), running [onInvoke].
ActionShortcut numberedAction(int i, {ActionInvoke? onInvoke}) {
  return ActionShortcut(
    id: "action_$i",
    label: "Action $i",
    description: "Action $i description",
    activators: [SingleActivator(_keys[i])],
    priority: i,
    run: onInvoke == null ? null : ActionRun.press(onInvoke),
  );
}

/// A heavy hold command "Remove" over one target, done word "Removed",
/// running [onEach] once the hold completes.
ActionShortcut removeHoldCommand({void Function()? onEach}) {
  return ActionShortcut(
    id: "remove",
    label: "Remove",
    description: "Remove it",
    activators: const [],
    priority: 1,
    run: ActionRun.hold(
      HoldPlan<String>(
        weight: HoldWeight.heavy,
        verb: "Remove",
        doneWord: "Removed",
        targets: (_) => {"it"},
        outcome: (_) => "Remove it? It does not come back.",
        each: (_, _) => onEach?.call(),
      ),
    ),
  );
}

/// A focused surface offering [actions], above the action row the panel
/// shows them in, [rowWidth] or 1000 wide.
final class ActionSurface extends StatelessWidget {
  const ActionSurface(this.actions, {this.rowWidth, super.key});

  final List<ActionShortcut> actions;
  final double? rowWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ManagedActionSet(
          shortcuts: actions,
          child: const Focus(
            autofocus: true,
            child: SizedBox.square(dimension: 40),
          ),
        ),
        SizedBox(width: rowWidth ?? 1000, child: const ActionRow()),
      ],
    );
  }
}
