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
}
