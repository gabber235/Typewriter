import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [CheckOptionSet] over the roles of two members: a role both hold is
/// checked, one only one holds says "1 of 2". A press on it gives it to
/// both, the next takes it from both, and the third gives each back what
/// it held. A disabled choice cannot be changed here.
@widgetbook.UseCase(name: "Default", type: CheckOptionSet)
Widget checkOptionSetUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(width: 320, child: _RoleChoices(enabled: enabled)),
    ),
  );
}

/// Four roles held by two members, the founder role fixed.
class _RoleChoices extends HookWidget {
  const _RoleChoices({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final held = useState([
      {"founder", "writer", "editor"},
      {"writer", "reader"},
    ]);
    return CheckOptionSet<String>(
      choices: const [
        CheckChoice(key: "founder", label: "Founder", enabled: false),
        CheckChoice(key: "writer", label: "Writer"),
        CheckChoice(key: "editor", label: "Editor"),
        CheckChoice(key: "reader", label: "Reader"),
      ],
      held: held.value,
      enabled: enabled,
      onChanged: (next) => held.value = next,
    );
  }
}
