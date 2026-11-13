import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The keys of one focused join code row: Space toggles the selection,
/// Shift+Space selects all, Escape clears it, C copies the code while
/// nothing is selected, and holding Delete revokes the code, or the whole
/// selection when the row is in it. The line under the row names the last
/// key's action.
@widgetbook.UseCase(name: "Default", type: JoinCodeTableRowShortcuts)
Widget joinCodeTableRowShortcutsUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: "Selected with another");
  final codes = storyJoinCodes(Generator(1), 2);
  return Story(
    [
      membership(roles: storyRoles, joinCodes: codes),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StoryBox(
        width: 560,
        child: _Row(codes: codes, selected: selected),
      ),
    ),
  );
}

/// One join code row whose shortcuts write what they did under it.
class _Row extends HookWidget {
  const _Row({required this.codes, required this.selected});

  final List<skir.JoinCode> codes;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final code = codes.first;
    final last = useState("Nothing pressed yet");
    final rows = useAnimatedRows(items: codes, identity: (code) => code.code);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space3,
      children: [
        JoinCodeTableRowShortcuts(
          code: code,
          onToggleSelection: () => last.value = "Toggled the selection",
          onSelectAll: () => last.value = "Selected all join codes",
          onClearSelection: () => last.value = "Cleared the selection",
          copy: ActionShortcut(
            id: "story_copy_join_code",
            label: "Copy join code",
            description: "Copy this join code",
            activators: const [SingleActivator(LogicalKeyboardKey.keyC)],
            priority: 1,
            run: ActionRun.press((_) => last.value = "Copied the join code"),
          ),
          isSelected: selected,
          hasSelection: selected,
          rows: rows,
          selectedIds: selected
              ? {for (final code in codes) code.code}
              : const {},
          child: Button(
            face: ButtonFace.bare,
            label: joinCodeUrl(code.code),
            autofocus: true,
            onPressed: () => last.value = "Clicked the row",
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space3),
              child: Text(
                joinCodeUrl(code.code),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        Text(last.value),
      ],
    );
  }
}
