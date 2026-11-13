import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The bar above the join codes while codes are selected: the count and
/// Revoke all, which holds. Clearing the selection here sets the count to
/// zero.
@widgetbook.UseCase(name: "Default", type: BulkJoinCodeActions)
Widget bulkJoinCodeActionsUseCase(BuildContext context) {
  final count = context.knobs.object.segmented(
    label: "Selected",
    options: const ["One", "Few", "Many"],
    initialOption: "Few",
  );
  final codes = storyJoinCodes(Generator(1), switch (count) {
    "One" => 1,
    "Many" => 60,
    _ => 3,
  });
  return Story(
    [
      membership(roles: storyRoles, joinCodes: codes),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space6),
          child: _Bar(codes: codes),
        ),
      ),
    ),
  );
}

/// Selects every code and builds the revoke hold over them, as the join
/// codes tab does.
class _Bar extends HookWidget {
  const _Bar({required this.codes});

  final List<skir.JoinCode> codes;

  @override
  Widget build(BuildContext context) {
    final rows = useAnimatedRows(items: codes, identity: (code) => code.code);
    final selected = useState({for (final code in codes) code.code});
    return BulkJoinCodeActions(
      selectedCount: selected.value.length,
      revocation: joinCodeRevocation(
        id: "story_revoke_join_codes",
        label: "Revoke join codes",
        priority: 2,
        targets: () => selected.value,
        rows: rows,
      ),
      onClearSelection: () => selected.value = const {},
    );
  }
}
