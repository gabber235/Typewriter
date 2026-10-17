import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "a pending destination selects the nearest authored field after mounting",
    (tester) async {
      final controller = PortableLocationRevealController();
      addTearDown(controller.dispose);
      final target = skir.ValueLocation(
        resource: skir.ResourceId(value: "page"),
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "title")],
        ),
      );
      final field = FocusNode();
      addTearDown(field.dispose);
      controller.request(target);
      await tester.pumpTestApp(
        child: Scaffold(
          body: PortableLocationRevealScope(
            controller: controller,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 900),
                  PortableLocationTarget(
                    location: target,
                    child: EditorTextField(focusNode: field),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        field.hasFocus || field.ancestors.any((node) => node.hasPrimaryFocus),
        isTrue,
      );
      expect(tester.getRect(find.byType(EditorTextField)).top, lessThan(600));
    },
  );
  testWidgets("root reveal chooses the requested inspector presentation", (
    tester,
  ) async {
    final controller = PortableLocationRevealController();
    addTearDown(controller.dispose);
    final root = skir.ValueLocation(
      resource: skir.ResourceId(value: "page"),
      path: skir.ValuePath(segments: const []),
    );
    final editor = FocusNode();
    final inspector = FocusNode();
    addTearDown(editor.dispose);
    addTearDown(inspector.dispose);
    controller.request(root, presentation: skir.PresentationRole.inspector);
    Widget target(skir.PresentationRole role, FocusNode focus) =>
        PortableLocationRevealScope(
          controller: controller,
          presentation: role,
          child: PortableLocationTarget(
            location: root,
            child: TextField(focusNode: focus),
          ),
        );
    await tester.pumpTestApp(
      child: Scaffold(
        body: Column(
          children: [
            target(skir.PresentationRole.editor, editor),
            target(skir.PresentationRole.inspector, inspector),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(inspector.hasFocus, isTrue);
    expect(editor.hasFocus, isFalse);
  });

  testWidgets("superseded queued reveal does not take keyboard focus", (
    tester,
  ) async {
    final controller = PortableLocationRevealController();
    addTearDown(controller.dispose);
    final location = skir.ValueLocation(
      resource: skir.ResourceId(value: "page"),
      path: skir.ValuePath(segments: const []),
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var current = true;
    controller.request(location, isCurrent: () => current);
    current = false;
    await tester.pumpTestApp(
      child: Scaffold(
        body: PortableLocationRevealScope(
          controller: controller,
          child: PortableLocationTarget(
            location: location,
            child: TextField(focusNode: focus),
          ),
        ),
      ),
    );
    expect(focus.hasFocus, isFalse);
  });
}
