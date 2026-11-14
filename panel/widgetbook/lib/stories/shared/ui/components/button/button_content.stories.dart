import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Every face [ButtonContent] paints, at rest and without its [Button]:
/// Unavailable keeps the text legible, Dense is the compact face.
@widgetbook.UseCase(name: "Every face", type: ButtonContent)
Widget buttonContentUseCase(BuildContext context) {
  final unavailable = context.knobs.boolean(label: "Unavailable");
  final dense = context.knobs.boolean(label: "Dense");
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final face in [
              ButtonFace.quiet,
              ButtonFace.filled,
              ButtonFace.outlined,
            ])
              ButtonContent(
                face: face,
                unavailable: unavailable,
                dense: dense,
                icon: const Icon(Icons.add),
                label: Text(face.name),
              ),
            ButtonContent(
              face: ButtonFace.filled,
              color: context.colors.danger,
              unavailable: unavailable,
              dense: dense,
              label: const Text("Delete"),
            ),
            ButtonContent(
              face: ButtonFace.icon,
              unavailable: unavailable,
              dense: dense,
              icon: const Icon(Icons.refresh),
            ),
            ButtonContent(
              face: ButtonFace.floating,
              unavailable: unavailable,
              dense: dense,
              icon: const Icon(Icons.add),
              label: const Text("New page"),
            ),
          ],
        ),
      ),
    ),
  );
}
