import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Apply lifecycle", type: ApplyControls)
Widget applyControlsUseCase(BuildContext context) {
  final reply = context.knobs.object.segmented(
    label: "Save reply",
    options: const ["Confirmed", "Lost"],
    initialOption: "Confirmed",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(width: 420, child: _ApplyScenario(uncertain: reply == "Lost")),
    ),
  );
}

final class _ApplyScenario extends HookWidget {
  const _ApplyScenario({required this.uncertain, this.group = false});
  final bool uncertain;
  final bool group;
  @override
  Widget build(BuildContext context) {
    final owner = useMemoized(
      () => fakeValueEditing(
        document: EditorDocument(
          rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
          confirmedValue: skir.DataValue.wrapStringValue("Saved value"),
          revision: 1,
        ),
        commitPolicy: EditorCommitPolicy.applyResource,
        validation: (path, value) => EditorMutationResult.applied(value),
        commit: (capture) async => uncertain
            ? MutationUncertain(
                message: "The external reply was lost",
                cause: StateError("Scripted reply loss"),
                stackTrace: StackTrace.current,
              )
            : MutationSuccess(
                revision: capture.expectedRevision + 1,
                value: capture.rootValue,
              ),
      ),
      [uncertain],
    );
    final control = useMemoized(owner.bindControl, [owner]);
    useEffect(
      () => () {
        control.dispose();
        owner.dispose();
      },
      [owner, control],
    );
    useListenable(owner);
    final text = useMemoized(() => TextEditingController(text: "Saved value"), [
      owner,
    ]);
    useEffect(() => text.dispose, [text]);
    final working = owner.value(editorRootPath).valueOrNull?.authoredString;
    useEffect(() {
      if (working != null && text.text != working) {
        text.text = working;
      }
      return null;
    }, [text, working]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: ValueKey(owner),
          controller: text,
          onChanged: (text) => owner.update(
            editorRootPath,
            skir.DataValue.wrapStringValue(text),
          ),
        ),
        if (group)
          EditingGroupPanel(workspace: owner.workspace, id: owner.groupId)
        else
          ApplyControls(control: control),
      ],
    );
  }
}

@widgetbook.UseCase(name: "Retained group", type: EditingGroupPanel)
Widget editingGroupPanelUseCase(BuildContext context) {
  return const Story(
    [],
    at: PanelLocation.component(
      SizedBox(
        width: 420,
        child: _ApplyScenario(uncertain: false, group: true),
      ),
    ),
  );
}
