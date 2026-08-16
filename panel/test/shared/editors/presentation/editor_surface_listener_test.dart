import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "support/editor_utils.dart";

void main() {
  testWidgets("rebuilds when its controller source changes", (tester) async {
    final source = TestEditorSource(
      rootType: const StringType(),
      value: const StringValue("Before"),
    );
    final controller = EditorController(source: source);
    addTearDown(controller.dispose);
    await tester.pumpTestApp(
      child: Material(child: EditorSurface(controller: controller)),
    );

    expect(find.text("Before"), findsOneWidget);

    controller.update(DataPath.root, const StringValue("After"));
    await tester.pump();

    expect(find.text("After"), findsOneWidget);
    expect(find.text("Before"), findsNothing);
  });
}
