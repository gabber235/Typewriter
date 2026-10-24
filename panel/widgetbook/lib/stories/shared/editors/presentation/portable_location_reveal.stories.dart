import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Reveal a field", type: PortableLocationTarget)
Widget portableLocationTargetUseCase(BuildContext context) =>
    const PortableLocationRevealStory();
@widgetbook.UseCase(
  name: "Navigation rendezvous",
  type: PortableLocationRevealScope,
)
Widget portableLocationRevealScopeUseCase(BuildContext context) =>
    const PortableLocationRevealStory();

class PortableLocationRevealStory extends HookWidget {
  const PortableLocationRevealStory({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(PortableLocationRevealController.new);
    useEffect(() => controller.dispose, [controller]);
    final location = skir.ValueLocation(
      resource: skir.ResourceId(value: "page"),
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "title")],
      ),
    );
    return FakeApp(
      child: SizedBox(
        width: 480,
        height: 450,
        child: Column(
          children: [
            TextButton(
              onPressed: () => controller.request(location),
              child: const Text("Go to title"),
            ),
            Expanded(
              child: PortableLocationRevealScope(
                controller: controller,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 600),
                      PortableLocationTarget(
                        location: location,
                        child: const EditorTextField(
                          decoration: InputDecoration(labelText: "Title"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
