import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";

/// The quest Tag the author renames to "Main quest" in the stories.
final questTag = tag("Quest");

/// Where the name of [questTag] is stored.
final questName = authoredFieldLocation(questTag.tagId, ["name"]);

/// What someone else saves to the quest Tag while the author's rename is
/// retained, by story knob label.
final savedChanges = <String, List<void Function(AuthoringEdit edit)>>{
  "Unchanged": const [],
  "Renamed elsewhere": [_rename("Side quest")],
  "Name cleared elsewhere": [
    (edit) => edit.set(questName, skir.DataValue.unfilled),
  ],
  "Removed elsewhere": [(edit) => edit.delete(questTag.tagId)],
  "Renamed twice elsewhere": [_rename("Side quest"), _rename("Changed again")],
};

void Function(AuthoringEdit edit) _rename(String name) =>
    (edit) => edit.set(questName, skir.DataValue.wrapStringValue(name));

/// A Realm holding [questTag], to which someone else saves [changes] once
/// the rename is retained.
List<Trait> retainedRenameWorld(
  List<void Function(AuthoringEdit edit)> changes,
) => [
  signedIn(ada, organization: acme),
  realm(tags: [questTag]),
  // Late enough that the rename is made against the first saved state.
  if (changes.isNotEmpty)
    remoteChanges(changes, every: const Duration(milliseconds: 700)),
];

/// Renames [questTag] to "Main quest" in the panel's editing of the story
/// Realm without saving it, then builds [builder] with the editing and the
/// group that holds the rename.
class RetainedRename extends StatelessWidget {
  const RetainedRename({required this.builder, super.key});

  final Widget Function(
    BuildContext context,
    RealmEditing workspace,
    EditGroupId group,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return RealmEditingScene(
      builder: (context, workspace, _) =>
          _Rename(workspace: workspace, builder: builder),
    );
  }
}

class _Rename extends HookWidget {
  const _Rename({required this.workspace, required this.builder});

  final RealmEditing workspace;
  final Widget Function(
    BuildContext context,
    RealmEditing workspace,
    EditGroupId group,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final group = useState<EditGroupId?>(null);
    useEffect(() {
      final form = workspace.attach(
        questTag.tagId,
        policy: EditorCommitPolicy.applyResource,
      );
      // The rename notifies the editing, which this scene watches, so it
      // waits until the scene finished building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        form.edit(
          label: "Rename quest",
          apply: (edit) =>
              edit.set(questName, skir.DataValue.wrapStringValue("Main quest")),
        );
        group.value = form.editingGroup;
      });
      return form.detach;
    }, [workspace]);
    final current = group.value;
    if (current == null) return const SizedBox.shrink();
    return builder(context, workspace, current);
  }
}
