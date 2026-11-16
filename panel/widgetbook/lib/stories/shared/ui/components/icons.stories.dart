import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _inlineSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"> '
    '<path fill="currentColor" d="M12 2 2 22h20L12 2zm0 5 6.5 13h-13L12 7z"/> '
    "</svg>";

/// An [Icones] from each source an author can give: an Iconify name loaded
/// from the Iconify hosts, inline SVG drawn in place, and a value that is
/// neither, which shows the broken image. Iconify icons load only with a
/// network; story tests show them broken.
@widgetbook.UseCase(name: "Default", type: Icones)
Widget iconesUseCase(BuildContext context) {
  final source = context.knobs.object.segmented(
    label: "Source",
    options: const ["Iconify", "Inline SVG", "Invalid"],
    initialOption: "Iconify",
  );
  final size = context.knobs.double.slider(
    label: "Size",
    initialValue: 24,
    min: 12,
    max: 64,
  );
  final icon = switch (source) {
    "Inline SVG" => _inlineSvg,
    "Invalid" => "not an icon",
    _ => "material-symbols:dns",
  };
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icones(icon, size: size),
            Icones(icon, size: size, color: context.colors.brand),
            Icones(icon, size: size, color: context.colors.danger),
          ],
        ),
      ),
    ),
  );
}
