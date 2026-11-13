import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/support/story.dart";

/// One join code setting: its title and description beside its control. A
/// long description wraps under the title and keeps the control in place.
@widgetbook.UseCase(name: "Default", type: SettingRow)
Widget settingRowUseCase(BuildContext context) {
  final longText = context.knobs.boolean(label: "Long description");
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 420,
    min: 240,
    max: 720,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      StoryBox(
        width: width,
        child: _Setting(longText: longText),
      ),
    ),
  );
}

/// Keeps the setting's value, as the join code settings do.
class _Setting extends HookWidget {
  const _Setting({required this.longText});

  final bool longText;

  @override
  Widget build(BuildContext context) {
    final on = useState(true);
    return SettingRow(
      title: "Single use",
      description: longText
          ? "The code stops working after one person joins with it, so a "
                "link that leaks to a public channel lets in nobody else "
                "once the person it was meant for has used it."
          : "The code stops working after one person joins.",
      trailing: SelectionCheck(
        value: on.value,
        onChanged: () => on.value = !on.value,
      ),
    );
  }
}
