import "package:typewriter_panel/typewriter_panel.dart";

/// One held button per weight, side by side: Discard draft holds light,
/// Remove member heavy and Delete resource permanent. Each types its done
/// word once its hold completes, and holds again after.
class HoldWeights extends HookWidget {
  const HoldWeights({super.key});

  @override
  Widget build(BuildContext context) {
    final commands = useMemoized(
      () => {for (final weight in HoldWeight.values) weight: _command(weight)},
    );
    return Padding(
      padding: EdgeInsets.all(context.spacing.space4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space4,
        children: [
          for (final MapEntry(key: weight, value: command) in commands.entries)
            CommandButton(
              command: command,
              label: command.label,
              face: switch (weight) {
                HoldWeight.light => ButtonFace.quiet,
                HoldWeight.heavy => ButtonFace.outlined,
                HoldWeight.permanent => ButtonFace.filled,
              },
              color: weight == HoldWeight.permanent
                  ? context.colors.danger
                  : context.colors.dangerText,
              icon: Icon(_icon[weight], size: 16),
              hint: "Destructive",
            ),
        ],
      ),
    );
  }
}

const _label = {
  HoldWeight.light: "Discard draft",
  HoldWeight.heavy: "Remove member",
  HoldWeight.permanent: "Delete resource",
};

const _doneWord = {
  HoldWeight.light: "Discarded",
  HoldWeight.heavy: "Removed",
  HoldWeight.permanent: "Deleted",
};

const _icon = {
  HoldWeight.light: Icons.undo,
  HoldWeight.heavy: Icons.person_remove_outlined,
  HoldWeight.permanent: Icons.delete_outline,
};

const _outcome = {
  HoldWeight.light: "Discard draft? Your unsaved changes are lost.",
  HoldWeight.heavy: "Remove Ada? They lose access straight away.",
  HoldWeight.permanent: "Delete Arrival and what it owns?",
};

ActionShortcut _command(HoldWeight weight) => ActionShortcut(
  id: "hold_weight_${weight.name}",
  label: _label[weight]!,
  description: _outcome[weight]!,
  activators: const [],
  priority: 0,
  show: false,
  run: ActionRun.hold(
    HoldPlan<HoldWeight>(
      weight: weight,
      targets: (_) => {weight},
      verb: _label[weight]!.split(" ").first,
      doneWord: _doneWord[weight]!,
      outcome: (_) => _outcome[weight]!,
      each: (_, _) {},
    ),
  ),
);
