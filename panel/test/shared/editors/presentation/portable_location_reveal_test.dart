import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final root = skir.ValueLocation(
    resource: skir.ResourceId(value: "page"),
    path: skir.ValuePath(segments: const []),
  );

  testWidgets(
    "a pending destination focuses and reveals the nearest authored field once it mounts",
    (tester) async {
      final controller = PortableLocationRevealController();
      addTearDown(controller.dispose);
      final title = skir.ValueLocation(
        resource: skir.ResourceId(value: "page"),
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "title")],
        ),
      );
      controller.request(title);

      final panel = await tester.showComponent(
        PortableLocationRevealScope(
          controller: controller,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 1200),
                PortableLocationTarget(
                  location: title,
                  child: EditorTextField(
                    decoration: InputDecoration(labelText: "Title"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(panel.hasFocusOn("Title"), isTrue);
      expect(
        tester.getRect(panel.labeled("Title")).top,
        lessThan(panel.world.window.height),
      );
    },
  );

  testWidgets(
    "a request to a mounted field reveals it while the panel is idle",
    (tester) async {
      final controller = PortableLocationRevealController();
      addTearDown(controller.dispose);
      final panel = await tester.showComponent(
        PortableLocationRevealScope(
          controller: controller,
          child: PortableLocationTarget(
            location: root,
            child: TextField(decoration: InputDecoration(labelText: "Title")),
          ),
        ),
      );

      controller.request(root);
      await tester.pump();
      await tester.pump();

      expect(panel.focused, "Title");
    },
  );

  testWidgets("a root reveal focuses the requested inspector presentation", (
    tester,
  ) async {
    final controller = PortableLocationRevealController();
    addTearDown(controller.dispose);
    controller.request(root, presentation: skir.PresentationRole.inspector);
    Widget target(skir.PresentationRole role, String label) =>
        PortableLocationRevealScope(
          controller: controller,
          presentation: role,
          child: PortableLocationTarget(
            location: root,
            child: TextField(decoration: InputDecoration(labelText: label)),
          ),
        );

    final panel = await tester.showComponent(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          target(skir.PresentationRole.workspace, "Workspace"),
          target(skir.PresentationRole.inspector, "Inspector"),
        ],
      ),
    );

    expect(panel.focused, "Inspector");
  });

  testWidgets("a superseded queued reveal does not take keyboard focus", (
    tester,
  ) async {
    final controller = PortableLocationRevealController();
    addTearDown(controller.dispose);
    var current = true;
    controller.request(root, isCurrent: () => current);
    current = false;

    final panel = await tester.showComponent(
      PortableLocationRevealScope(
        controller: controller,
        child: PortableLocationTarget(
          location: root,
          child: TextField(decoration: InputDecoration(labelText: "Title")),
        ),
      ),
    );

    expect(panel.focused, isNull);
  });
}
