import "package:typewriter_panel/typewriter_panel.dart";

/// Makes retained conflict work and its shared resolution action visible.
final class AuthoringConflictNotice extends StatelessWidget {
  const AuthoringConflictNotice({
    required this.workspace,
    required this.group,
    super.key,
  });
  final RealmEditing workspace;
  final EditGroupId group;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Saved values changed", style: context.theme.textTheme.titleSmall),
        Text(
          "Your edits are still here. Review them before saving.",
          style: context.text.sentence,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Button(
            label: "Review changes",
            onPressed: () => showAdvancedDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text("Review changes"),
                content: SizedBox(
                  width: 700,
                  child: SingleChildScrollView(
                    child: RealmEditingReview(
                      workspace: workspace,
                      id: group,
                      onResolved: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ),
                actions: [
                  Button(
                    label: "Close",
                    // Keep mine takes focus when the review offers it.
                    autofocus:
                        workspace
                            .conflictReview(group)
                            ?.comparison
                            ?.canKeepMine !=
                        true,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
