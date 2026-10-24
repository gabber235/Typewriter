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
        const Text("Your edits are still here. Review them before saving."),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => showDialog<void>(
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
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
            child: const Text("Review changes"),
          ),
        ),
      ],
    ),
  );
}
