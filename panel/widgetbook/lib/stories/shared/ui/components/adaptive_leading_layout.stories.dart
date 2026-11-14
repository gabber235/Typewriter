import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [AdaptiveLeadingLayout] of a checkbox like leading control, a label
/// and a suffix: drag Width down to watch the suffix go first, then the
/// label, leaving only the leading control.
@widgetbook.UseCase(name: "Default", type: AdaptiveLeadingLayout)
Widget adaptiveLeadingLayoutUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 320,
    min: 24,
    max: 480,
  );
  final suffix = context.knobs.boolean(label: "Suffix", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.borderSubtle),
          ),
          child: SizedBox(
            width: width,
            child: AdaptiveLeadingLayout(
              padding: const EdgeInsets.all(8),
              leading: const Icon(Icons.check_box_outline_blank),
              center: const Text(
                "Repeat every day",
                overflow: TextOverflow.ellipsis,
              ),
              suffix: suffix ? const Text("Optional") : null,
            ),
          ),
        ),
      ),
    ),
  );
}
