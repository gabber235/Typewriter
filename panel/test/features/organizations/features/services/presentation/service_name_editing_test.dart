import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("valid service name typing retains the focused input", (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await tester.pumpTestApp(child: fixture.renderer);
    await tester.showKeyboard(find.byType(TextFormField));
    await tester.pumpAndSettle();
    final before = tester.state<EditableTextState>(find.byType(EditableText));
    final controller = before.widget.controller;
    final focusNode = before.widget.focusNode;
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.enterText(find.byType(TextFormField), "gabber236");
    await tester.pumpAndSettle();

    final after = tester.state<EditableTextState>(find.byType(EditableText));
    expect(after, same(before));
    expect(after.widget.controller, same(controller));
    expect(after.widget.focusNode, same(focusNode));
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(controller.text, "gabber236");
    expect(fixture.name, "gabber236");
    expect(find.bySemanticsLabel("Presentation error"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("rejected service name typing retains input focus and text", (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await tester.pumpTestApp(child: fixture.renderer);
    await tester.showKeyboard(find.byType(TextFormField));
    await tester.pumpAndSettle();
    final before = tester.state<EditableTextState>(find.byType(EditableText));
    final controller = before.widget.controller;
    final focusNode = before.widget.focusNode;
    expect(focusNode.hasPrimaryFocus, isTrue);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: "ga",
        selection: TextSelection(baseOffset: 0, extentOffset: 1),
      ),
    );
    await tester.pumpAndSettle();

    const message =
        "Use at least three lowercase letters or digits separated by underscores";
    final frame = find.byType(PortableDiagnosticFrame);
    expect(
      find.descendant(of: frame, matching: find.text(message)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel("Presentation error"), findsNothing);
    expect(fixture.name, "gabber235");
    expect(tester.takeException(), isNull);
    final after = tester.state<EditableTextState>(find.byType(EditableText));
    expect(
      {
        "same editable state": identical(after, before),
        "same controller": identical(after.widget.controller, controller),
        "same focus node": identical(after.widget.focusNode, focusNode),
        "primary focus": after.widget.focusNode.hasPrimaryFocus,
        "typed name": after.widget.controller.text,
      },
      {
        "same editable state": true,
        "same controller": true,
        "same focus node": true,
        "primary focus": true,
        "typed name": "ga",
      },
      reason: "A validation notice must preserve the input being edited",
    );
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );

    await tester.enterText(find.byType(TextFormField), "gabber236");
    await tester.pumpAndSettle();
    expect(fixture.name, "gabber236");
    expect(find.text(message), findsNothing);
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(before),
    );
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.enterText(find.byType(TextFormField), "ga");
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: frame, matching: find.text(message)),
      findsOneWidget,
    );
    expect(fixture.name, "gabber236");
    expect(controller.text, "ga");
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(before),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("an older service rejection cannot return after a correction", (
    tester,
  ) async {
    final fixture = _Fixture();
    final operations = PortableOperationResults();
    addTearDown(fixture.dispose);
    addTearDown(operations.dispose);
    final binding = skir.ExpressionBindingId(value: "service.identity.name");
    final reference = skir.BindingRef(bindingId: binding, path: editorRootPath);
    final target = PortableDiagnosticTarget.binding(reference);
    final context = fixture.host.rootInvocation;
    final invalid = fixture.owner
        .validate(
          editorRootPath.field("name"),
          skir.DataValue.wrapStringValue("ga"),
        )
        .toPortablePresentationResult(
          binding: binding,
          sourcePath: editorRootPath.field("name"),
        );
    final olderResponse = Completer<PortablePresentationWriteResult>();
    final newerResponse = Completer<PortablePresentationWriteResult>();
    final older = operations.run(
      key: PortableOperationKey.write(target),
      input: PortableDiagnosticObservation(
        target: target,
        value: fixture.host.read(reference, context: context),
      ),
      operation: () => olderResponse.future,
    );
    final newer = operations.run(
      key: PortableOperationKey.write(target),
      input: PortableDiagnosticObservation(
        target: target,
        value: fixture.host.read(reference, context: context),
      ),
      operation: () => newerResponse.future,
    );
    newerResponse.complete(
      await fixture.host.write(
        reference,
        skir.DataValue.wrapStringValue("gabber236"),
        context: context,
      ),
    );
    await newer;
    olderResponse.complete(invalid);
    await older;
    expect(fixture.name, "gabber236");
    expect(operations.value.outcomes, isEmpty);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "graph layout during rejected service name typing stays exception free",
    (tester) async {
      final fixture = _Fixture();
      final graphWidth = ValueNotifier<double>(300);
      addTearDown(fixture.dispose);
      addTearDown(graphWidth.dispose);
      await tester.pumpTestApp(
        child: Row(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: graphWidth,
              builder: (context, width, child) =>
                  SizedBox(width: width, height: 400, child: child),
              child: Graph(
                data: GraphData(
                  cellSize: 50,
                  elements: [
                    GraphElement(
                      id: const GraphIdentifier("service:test"),
                      x: 0,
                      y: 0,
                      width: 2,
                      height: 2,
                      builder: (_) => const SizedBox.expand(),
                    ),
                  ],
                  edges: const [],
                ),
              ),
            ),
            Expanded(child: fixture.renderer),
          ],
        ),
      );
      await tester.showKeyboard(find.byType(TextFormField));
      await tester.pumpAndSettle();
      final before = tester.state<EditableTextState>(find.byType(EditableText));
      expect(before.widget.focusNode.hasPrimaryFocus, isTrue);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField), "ga");
      graphWidth.value = 301;
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: "Graph layout must not inspect a deactivated focused input",
      );
      expect(find.byType(ErrorWidget), findsNothing);
      final after = tester.state<EditableTextState>(find.byType(EditableText));
      expect(after, same(before));
      expect(after.widget.focusNode.hasPrimaryFocus, isTrue);
      expect(after.widget.controller.text, "ga");
      expect(fixture.name, "gabber235");
    },
  );
}

final class _Fixture {
  _Fixture() {
    final service = Service(
      serviceId: skir.recordId("service:test"),
      revision: 1,
      name: "gabber235",
      role: HostServiceRole(version: "1.0.0"),
      createdAt: DateTime.utc(2026),
    );
    final snapshot = service.editorSnapshot;
    owner = fakeValueEditing(
      document: snapshot.document,
      snapshot: snapshot,
      commitPolicy: EditorCommitPolicy.applyResource,
    );
    host = serviceIdentityPortablePresentationHost(identityOwner: owner);
  }

  late final ValueEditing owner;
  late final BoundPresentationHost host;

  Widget get renderer => Material(
    child: SelectableScope(
      id: ServiceIdentifier(skir.recordId("service:test")),
      child: PortablePresentationRenderer(host: host),
    ),
  );

  String? get name =>
      owner.value(editorRootPath.field("name")).valueOrNull?.authoredString;

  void dispose() {
    host.dispose();
    owner.dispose();
  }
}
