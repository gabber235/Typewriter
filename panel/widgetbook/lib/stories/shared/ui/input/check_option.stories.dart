import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// [CheckOption]s for a set of known choices, as the inspector shows them
/// for one item or for several: a choice every item holds is checked, one
/// none holds is empty, and one only some hold is striped and says how many.
/// A press gives a choice to every item, or takes it from all of them.
@widgetbook.UseCase(name: "Default", type: CheckOption)
Widget checkOptionUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(width: 320, child: _CheckOptions(enabled: enabled)),
    ),
  );
}

/// Three choices held by all, some and none of three items; a press gives a
/// choice to all of them, or takes it from all.
class _CheckOptions extends HookWidget {
  const _CheckOptions({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final held = useState({"build": 3, "fly": 1, "chat": 0});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: name, value: count) in held.value.entries)
          CheckOption(
            label: name,
            value: count == 3
                ? true
                : count == 0
                ? false
                : null,
            detail: "$count of 3",
            onPressed: enabled
                ? () => held.value = {...held.value, name: count == 3 ? 0 : 3}
                : null,
          ),
      ],
    );
  }
}
