import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// One small label of a join code's policy, in each tone the join code
/// badges use.
@widgetbook.UseCase(name: "Default", type: TypeBadge)
Widget typeBadgeUseCase(BuildContext context) {
  final tone = context.knobs.object.segmented(
    label: "Tone",
    options: const ["Single use", "Multi use", "Auto accept"],
    initialOption: "Single use",
  );
  final label = context.knobs.string(label: "Label", initialValue: tone);
  return Story(
    const [],
    at: PanelLocation.component(
      Center(
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            final (icon, color, background) = switch (tone) {
              "Multi use" => (
                Icons.all_inclusive_rounded,
                scheme.onSurfaceVariant,
                Surface.colorOf(context),
              ),
              "Auto accept" => (
                Icons.flash_on_rounded,
                context.colors.brandText,
                scheme.primaryContainer,
              ),
              _ => (
                Icons.looks_one_rounded,
                scheme.tertiary,
                scheme.tertiaryContainer,
              ),
            };
            return TypeBadge(
              icon: icon,
              label: label,
              color: color,
              backgroundColor: background,
            );
          },
        ),
      ),
    ),
  );
}
