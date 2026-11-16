import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A role picker wrapped in [SelectionInitialization]: with one choice, or
/// a default among the choices, it picks for the user once; with two
/// choices and no default it waits for the user. Explicit never picks.
@widgetbook.UseCase(name: "Default", type: SelectionInitialization)
Widget selectionInitializationUseCase(BuildContext context) {
  final choices = context.knobs.object.segmented(
    label: "Choices",
    options: const ["One", "Two", "Two with default"],
    initialOption: "One",
  );
  final policy = context.knobs.object.segmented(
    label: "Policy",
    options: SelectionInitializationPolicy.values,
    initialOption: SelectionInitializationPolicy.automatic,
    labelBuilder: (policy) => policy.name,
  );
  final roles = choices == "One"
      ? const ["Editor"]
      : const ["Editor", "Viewer"];
  return Story(
    const [],
    at: PanelLocation.component(
      HookBuilder(
        builder: (context) {
          final selected = useState<String?>(null);
          return SelectionInitialization<String>(
            selected: selected.value,
            choices: roles,
            defaultValue: choices == "Two with default" ? "Viewer" : null,
            policy: policy,
            onSelected: (role) => selected.value = role,
            child: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final role in roles)
                    PanelRow(
                      dense: true,
                      title: Text(role),
                      selected: selected.value == role,
                      onPressed: () => selected.value = role,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
