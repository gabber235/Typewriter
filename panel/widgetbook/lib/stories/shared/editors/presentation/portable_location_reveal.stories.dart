import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Fields that a link or a new resource can reveal: a reveal scrolls the
/// field into view and focuses it, and a reveal of a block focuses its
/// first empty field. With many fields the target starts off screen.
@widgetbook.UseCase(name: "Reveal a field", type: PortableLocationTarget)
Widget portableLocationTargetUseCase(BuildContext context) => Story(
  context.knobs.traits("Motion", {
    "Full": const [],
    "Reduced": const [reducedMotion],
  }),
  at: PanelLocation.component(
    PortableLocationTargetStory(
      many: context.knobs.boolean(label: "Many fields", initialValue: true),
      width: context.knobs.width(const {"Inspector": 420, "Narrow": 240}),
    ),
  ),
);

/// A quest form under a [PortableLocationRevealScope], with buttons that
/// request reveals of its fields.
class PortableLocationTargetStory extends HookWidget {
  const PortableLocationTargetStory({
    required this.many,
    required this.width,
    super.key,
  });

  final bool many;
  final double width;

  static final _quest = skir.ResourceId(value: "quest:lantern");

  static skir.ValueLocation _at(List<String> fields) => skir.ValueLocation(
    resource: _quest,
    path: skir.ValuePath(
      segments: [
        for (final field in fields) skir.PathSegment.createField(name: field),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(PortableLocationRevealController.new);
    useEffect(() => controller.dispose, [controller]);
    Widget field(List<String> path, String label, String text) {
      return PortableLocationTarget(
        location: _at(path),
        isEmpty: () => text.isEmpty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            Text(label),
            EditorTextField(text: text, semanticLabel: label),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      height: 420,
      child: PortableLocationRevealScope(
        controller: controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Button(
                  label: "Reveal amount",
                  onPressed: () =>
                      controller.request(_at(const ["reward", "amount"])),
                ),
                Button(
                  label: "Reveal reward",
                  onPressed: () => controller.request(
                    _at(const ["reward"]),
                    focus: RevealFocus.firstEmptyField,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    field(const ["title"], "Title", "Find the lantern"),
                    if (many)
                      for (var index = 1; index <= 12; index++)
                        field(["step$index"], "Step $index", "Talk to Ada"),
                    PortableLocationTarget(
                      location: _at(const ["reward"]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: [
                          field(const ["reward", "item"], "Item", "Lantern"),
                          field(const ["reward", "amount"], "Amount", ""),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
