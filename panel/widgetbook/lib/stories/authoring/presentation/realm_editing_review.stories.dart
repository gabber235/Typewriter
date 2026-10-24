import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

/// Saved Realm states the retained local rename is reviewed against.
enum RealmReviewState { unsaved, savedChanged, removedElsewhere }

@widgetbook.UseCase(name: "Retained rename", type: RealmEditingReview)
Widget realmEditingReviewUseCase(BuildContext context) =>
    RealmEditingReviewStory(
      state: context.knobs.object.dropdown(
        label: "Saved Realm state",
        options: RealmReviewState.values,
        initialOption: RealmReviewState.unsaved,
        labelBuilder: (state) => switch (state) {
          RealmReviewState.unsaved => "Unchanged since editing",
          RealmReviewState.savedChanged => "Renamed elsewhere",
          RealmReviewState.removedElsewhere => "Removed elsewhere",
        },
      ),
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 720,
        min: 360,
        max: 960,
      ),
    );

/// Renames a quest Tag locally, optionally changes the saved Realm under it,
/// and reviews the retained group through the shared editing workspace.
class RealmEditingReviewStory extends HookWidget {
  const RealmEditingReviewStory({
    this.state = RealmReviewState.unsaved,
    this.width = 720,
    super.key,
  });

  final RealmReviewState state;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scenario = useMemoized(() {
      final tag = skir.ResourceId(value: "tag:quest");
      final original = fixtureAuthoringDocument(
        tags: [
          Tag(
            tagId: tag,
            name: "Quest",
            color: Colors.amber,
            parentIds: const [],
            placement: GraphPlacement(x: 0, y: 0, width: 7, height: 1),
          ),
        ],
      );
      final transport = ScriptedAuthoringTransport(AsyncData(original));
      final work = ScopedWorkSession();
      final editing = RealmEditing(
        persistence: transport.persistence,
        submissions: work,
        initial: original,
      );
      final form = editing.attach(
        tag,
        policy: EditorCommitPolicy.applyResource,
      );
      final name = authoredFieldLocation(tag, ["name"]);
      form.edit(
        label: "Rename quest",
        apply: (edit) =>
            edit.set(name, skir.DataValue.wrapStringValue("Main quest")),
      );
      if (state != RealmReviewState.unsaved) {
        final saved = state == RealmReviewState.removedElsewhere
            ? original.copyWith(entries: {})
            : (AuthoringEdit.fromDocument(original)
                    ..set(name, skir.DataValue.wrapStringValue("Side quest")))
                  .toDocument();
        transport.publish(AsyncData(saved));
        editing.acceptConfirmed(saved);
      }
      return (editing: editing, form: form, transport: transport, work: work);
    }, [state]);
    useEffect(
      () => () {
        scenario.form.detach();
        scenario.editing.dispose();
        scenario.transport.dispose();
        scenario.work.dispose();
      },
      [scenario],
    );
    final resolved = useState(false);
    useEffect(() {
      resolved.value = false;
      return null;
    }, [scenario]);
    return FakeApp(
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RealmEditingReview(
                  workspace: scenario.editing,
                  id: scenario.form.editingGroup,
                  onResolved: () => resolved.value = true,
                ),
                if (resolved.value) const Text("Review resolved"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
