import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "selection_editor_source_test_support.dart";

void main() {
  group("SelectionEditorSource values", () {
    test("reports loading while selected values resolve", () {
      final container = ProviderContainer.test();
      container
          .read(selectionProvider.notifier)
          .select(_loadingIdentifier("loading"), isMultiSelect: false);

      expect(
        container.read(_sourceProvider).value(DataPath.root),
        isA<LoadingEditorValue>(),
      );
    });

    test("reports invalid for an empty selection", () {
      final container = ProviderContainer.test();

      expect(
        container.read(_sourceProvider).value(DataPath.root),
        isA<InvalidEditorValue>(),
      );
    });

    test("uses structural equality for selected values", () {
      final first = _identifier(
        "first",
        EditorValue.ready(ListValue([const StringValue("same")])),
      );
      final second = _identifier(
        "second",
        EditorValue.ready(ListValue([const StringValue("same")])),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final state = container.read(_sourceProvider).value(DataPath.root);

      expect(state, isA<ReadyEditorValue>());
      expect(state.valueOrNull, ListValue([const StringValue("same")]));
    });

    test("reports conflict when editor states or values differ", () {
      final ready = _identifier(
        "ready",
        const EditorValue.ready(StringValue("value")),
      );
      final conflict = _identifier("conflict", const EditorValue.conflict());
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([ready, conflict]);

      expect(
        container.read(_sourceProvider).value(DataPath.root),
        isA<ConflictEditorValue>(),
      );
    });

    test("combines invalid diagnostics", () {
      final first = _invalidIdentifier("first", "First invalid");
      final second = _invalidIdentifier("second", "Second invalid");
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final state = container.read(_sourceProvider).value(DataPath.root);

      expect((state as InvalidEditorValue).diagnostics, hasLength(2));
    });
  });

  group("SelectionEditorSource type projection", () {
    test("projects common editable record fields", () {
      final first = _identifier(
        "first",
        _missingEditorValue(),
        rootType: _recordType(["shared", "first"]),
      );
      final second = _identifier(
        "second",
        _missingEditorValue(),
        rootType: _recordType(["shared", "second"]),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final type = container.read(inspectedRootTypeProvider)! as RecordType;

      expect(type.fields.keys, ["shared"]);
      expect(container.read(_sourceProvider).rootType, same(type));
    });
  });

  group("SelectionEditorSource mutations", () {
    test("fans out typed mutations and returns the accepted value", () {
      final first = _identifier(
        "first",
        _missingEditorValue(),
        mutation: const EditorMutationResult.applied(StringValue("accepted")),
      );
      final second = _identifier(
        "second",
        _missingEditorValue(),
        mutation: const EditorMutationResult.applied(StringValue("accepted")),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);
      final path = DataPath.root.field("name");

      final result = container
          .read(_sourceProvider)
          .update(path, const StringValue("requested"));

      expect(
        (result as AppliedEditorMutation).value,
        const StringValue("accepted"),
      );
      expect(first.latest!.updatedPath, path);
      expect(first.latest!.updatedValue, const StringValue("requested"));
      expect(second.latest!.updatedPath, path);
    });

    test("reports conflict when selections accept different values", () {
      final first = _identifier(
        "first",
        _missingEditorValue(),
        mutation: const EditorMutationResult.applied(StringValue("first")),
      );
      final second = _identifier(
        "second",
        _missingEditorValue(),
        mutation: const EditorMutationResult.applied(StringValue("second")),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final result = container
          .read(_sourceProvider)
          .update(DataPath.root, const StringValue("requested"));

      expect(result, isA<ConflictingEditorMutation>());
    });

    test("combines invalid mutation diagnostics", () {
      final first = _identifier(
        "first",
        _missingEditorValue(),
        mutation: _invalidMutation("First invalid"),
      );
      final second = _identifier(
        "second",
        _missingEditorValue(),
        mutation: _invalidMutation("Second invalid"),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final result = container
          .read(_sourceProvider)
          .update(DataPath.root, const StringValue("requested"));

      expect((result as InvalidEditorMutation).diagnostics, hasLength(2));
    });

    test("does not mutate earlier selections when a later one rejects", () {
      final first = _identifier(
        "first",
        const EditorValue.ready(StringValue("before")),
        mutation: const EditorMutationResult.applied(StringValue("after")),
      );
      final second = _identifier(
        "second",
        const EditorValue.ready(StringValue("before")),
        mutation: _invalidMutation("Rejected"),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final result = container
          .read(_sourceProvider)
          .update(DataPath.root, const StringValue("after"));

      expect(result, isA<InvalidEditorMutation>());
      expect(first.latest!.updatedPath, isNull);
      expect(first.latest!.updatedValue, isNull);
      expect(second.latest!.updatedPath, isNull);
    });
  });
}
