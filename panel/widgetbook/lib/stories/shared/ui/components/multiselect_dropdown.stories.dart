import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _roles = {
  "Owner": Colors.red,
  "Admin": Colors.orange,
  "Writer": Colors.blue,
  "Builder": Colors.green,
  "Reviewer": Colors.purple,
  "Guest": Colors.blueGrey,
};

/// A [MultiselectDropdown] of organization roles: none, a few or every role
/// picked, in a wide or narrow field where the chips wrap.
@widgetbook.UseCase(name: "Default", type: MultiselectDropdown)
Widget multiselectDropdownUseCase(BuildContext context) {
  final picked = context.knobs.object.segmented(
    label: "Selected",
    options: const [0, 2, 6],
    labelBuilder: (count) => switch (count) {
      0 => "None",
      2 => "Few",
      _ => "All",
    },
    initialOption: 2,
  );
  final narrow = context.knobs.boolean(label: "Narrow");
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: narrow ? 240 : 420,
        child: _RolePicker(initial: picked, enabled: enabled),
      ),
    ),
  );
}

class _RolePicker extends HookWidget {
  const _RolePicker({required this.initial, required this.enabled});

  final int initial;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = useState(_roles.keys.take(initial).toList());
    final field = useInputFieldController(inputDebugLabel: "Roles");
    return MultiselectDropdown<String>(
      inputFieldController: field,
      enabled: enabled,
      dropdownMenuEntries: [
        for (final role in _roles.keys)
          DropdownMenuEntry(value: role, label: role),
      ],
      selectedItems: selected.value,
      onSelectionChanged: (roles) => selected.value = roles,
      itemBuilder: (role) => SmallChip(
        label: role,
        color: _roles[role]!,
        onDelete: () => selected.value = [
          for (final kept in selected.value)
            if (kept != role) kept,
        ],
      ),
    );
  }
}
