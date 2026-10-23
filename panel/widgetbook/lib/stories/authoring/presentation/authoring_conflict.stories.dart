import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Retained conflict", type: AuthoringConflictNotice)
Widget authoringConflictNoticeUseCase(BuildContext context) =>
    authoringConflictStory(
      comparison: false,
      unavailable: context.knobs.boolean(
        label: "Saved observation unavailable",
      ),
      removed: context.knobs.boolean(label: "Resource removed"),
      unfilled: context.knobs.boolean(label: "Saved name Unfilled"),
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 420,
        min: 320,
        max: 800,
      ),
    );

@widgetbook.UseCase(
  name: "Complete group comparison",
  type: AuthoringConflictComparison,
)
Widget authoringConflictComparisonUseCase(BuildContext context) =>
    authoringConflictStory(
      comparison: true,
      removed: context.knobs.boolean(label: "Resource removed"),
      unfilled: context.knobs.boolean(label: "Saved name Unfilled"),
      connections: context.knobs.boolean(label: "Relation conflict"),
      stale: context.knobs.boolean(label: "Review changed again"),
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 700,
        min: 320,
        max: 900,
      ),
    );

Widget authoringConflictStory({
  required bool comparison,
  double width = 700,
  bool removed = false,
  bool unfilled = false,
  bool unavailable = false,
  bool connections = false,
  bool stale = false,
}) => FakeApp(
  child: SizedBox(
    width: width,
    child: _ConflictScenario(
      comparison: comparison,
      removed: removed,
      unfilled: unfilled,
      unavailable: unavailable,
      connections: connections,
      stale: stale,
    ),
  ),
);

final class _ConflictScenario extends HookWidget {
  const _ConflictScenario({
    required this.comparison,
    required this.removed,
    required this.unfilled,
    required this.unavailable,
    required this.connections,
    required this.stale,
  });
  final bool comparison;
  final bool removed;
  final bool unfilled;
  final bool unavailable;
  final bool connections;
  final bool stale;
  @override
  Widget build(BuildContext context) {
    final scenario = useMemoized(() {
      final tag = skir.ResourceId(value: "tag:quest");
      final original = fixtureAuthoringDocument(
        tags: [
          Tag(
            tagId: tag,
            name: "Quest",
            color: Colors.grey,
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
        apply: (edit) {
          edit.set(name, skir.DataValue.wrapStringValue("Main quest"));
          if (connections) {
            edit.applyPrepared(
              skir.PreparedEdit(
                catalog: original.generation,
                expectations: [
                  skir.EditExpectation.createLinks(
                    resource: tag,
                    contract: skir.RelationId(value: "tag.parents"),
                    direction: skir.TraversalDirection.both,
                    expected: const [],
                  ),
                ],
                intents: const [],
              ),
            );
          }
        },
      );
      final remote = AuthoringEdit.fromDocument(original)
        ..set(
          name,
          unfilled
              ? skir.DataValue.unfilled
              : skir.DataValue.wrapStringValue("Side quest"),
        );
      final saved = removed
          ? original.copyWith(entries: {})
          : remote.toDocument().copyWith(
              links: connections
                  ? [
                      skir.LinkProjection(
                        contract: skir.RelationId(value: "tag.parents"),
                        first: tag,
                        second: skir.ResourceId(value: "tag:location"),
                        firstLocation: null,
                        secondLocation: null,
                      ),
                    ]
                  : const [],
            );
      transport.publish(AsyncData(saved));
      editing.acceptConfirmed(saved);
      if (unavailable) {
        transport.refreshFailure = StateError("Saved observation unavailable");
      }
      final review = const RealmEditModel().review(
        form.editingGroup,
        editing.workspace.inspectUnsubmitted(form.editingGroup),
      );
      if (stale && !removed) {
        editing.acceptConfirmed(
          (AuthoringEdit.fromDocument(saved)
                ..set(name, skir.DataValue.wrapStringValue("Changed again")))
              .toDocument(),
        );
      }
      return (
        editing: editing,
        form: form,
        transport: transport,
        work: work,
        review: review,
      );
    }, [comparison, removed, unfilled, unavailable, connections, stale]);
    useEffect(
      () => () {
        scenario.form.detach();
        scenario.editing.dispose();
        scenario.transport.dispose();
        scenario.work.dispose();
      },
      [scenario],
    );
    useListenable(scenario.editing);
    if (scenario.editing.state.groups.isEmpty) {
      return const Text("Changes are settled");
    }
    if (scenario.editing.state.groups[scenario.form.editingGroup]?.phase
        is EditGroupDirty) {
      return const Text("Your changes are ready to save");
    }
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space3),
        child: comparison
            ? AuthoringConflictComparison(
                review: scenario.review,
                onKeepMine: scenario.review.canKeepMine
                    ? () => scenario.editing.resolveConflict(
                        scenario.review,
                        AuthoringConflictChoice.keepMine,
                      )
                    : null,
                onUseSaved: () => scenario.editing.resolveConflict(
                  scenario.review,
                  AuthoringConflictChoice.useSaved,
                ),
              )
            : AuthoringConflictNotice(
                workspace: scenario.editing,
                group: scenario.form.editingGroup,
              ),
      ),
    );
  }
}
