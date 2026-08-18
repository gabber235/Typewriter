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
        ListValue([const StringValue("same")]),
      );
      final second = _identifier(
        "second",
        ListValue([const StringValue("same")]),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final state = container.read(_sourceProvider).value(DataPath.root);

      expect(state, isA<ReadyEditorValue>());
      expect(state.valueOrNull, ListValue([const StringValue("same")]));
    });

    test("reports conflict when selected values differ", () {
      final ready = _identifier("ready", const StringValue("value"));
      final conflict = _identifier("conflict", const StringValue("other"));
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([ready, conflict]);

      expect(
        container.read(_sourceProvider).value(DataPath.root),
        isA<ConflictEditorValue>(),
      );
    });

    test("combines invalid diagnostics", () {
      final first = _identifier("first", const StringValue("first"));
      final second = _identifier("second", const StringValue("second"));
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final state = container
          .read(_sourceProvider)
          .value(DataPath.root.field("missing"));

      expect((state as InvalidEditorValue).diagnostics, hasLength(2));
    });

    test("read getters never notify or resynchronize targets", () {
      final identifier = _identifier("stable", const StringValue("value"));
      final container = ProviderContainer.test();
      container
          .read(selectionProvider.notifier)
          .select(identifier, isMultiSelect: false);
      final source = container.read(_sourceProvider);
      var notifications = 0;
      source.addListener(() => notifications++);

      expect(source.document, isNotNull);
      expect(source.value(DataPath.root), isA<ReadyEditorValue>());
      expect(source.saveState(DataPath.root).phase, EditorSavePhase.idle);
      expect(notifications, 0);
    });

    test("provider refresh skips unchanged documents", () {
      final identifier = _identifier("stable", const StringValue("value"));
      final container = ProviderContainer.test();
      container
          .read(selectionProvider.notifier)
          .select(identifier, isMultiSelect: false);
      final source = container.read(_sourceProvider);
      var notifications = 0;
      source.addListener(() => notifications++);

      container
        ..invalidate(selectedProvider)
        ..read(inspectedSelectionProvider);

      expect(source.value(DataPath.root).valueOrNull, identifier.current);
      expect(notifications, 0);
    });

    test("provider refresh applies remote values and metadata", () {
      final identifier = _identifier("remote", const StringValue("before"));
      final container = ProviderContainer.test();
      container
          .read(selectionProvider.notifier)
          .select(identifier, isMultiSelect: false);
      final source = container.read(_sourceProvider);
      var notifications = 0;
      source.addListener(() => notifications++);

      identifier
        ..current = const StringValue("after")
        ..revision = 2
        ..readOnly = true;
      container
        ..invalidate(selectedProvider)
        ..read(inspectedSelectionProvider);

      expect(source.value(DataPath.root).valueOrNull, identifier.current);
      expect(source.document?.revision, 2);
      expect(source.document?.readOnly, isTrue);
      expect(notifications, greaterThan(0));
    });

    testWidgets("renders remote deletion once before removing selection", (
      tester,
    ) async {
      final identifier = _identifier("deleted", const StringValue("before"));
      final container = ProviderContainer.test();
      container
          .read(selectionProvider.notifier)
          .select(identifier, isMultiSelect: false);
      final source = container.read(_sourceProvider);
      expect(source.value(DataPath.root), isA<ReadyEditorValue>());

      identifier.deleted = true;
      container
        ..invalidate(selectedProvider)
        ..read(inspectedSelectionProvider);

      expect(
        source.saveState(DataPath.root).phase,
        EditorSavePhase.deletedElsewhere,
      );
      expect(container.read(selectionProvider), [identifier]);

      await tester.pump();
      expect(container.read(selectionProvider), isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
    });
  });

  group("SelectionEditorSource type projection", () {
    test("projects common editable record fields", () {
      final first = _identifier(
        "first",
        _recordValue(["shared", "first"]),
        rootType: _recordType(["shared", "first"]),
      );
      final second = _identifier(
        "second",
        _recordValue(["shared", "second"]),
        rootType: _recordType(["shared", "second"]),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final type = container.read(inspectedRootTypeProvider)! as RecordType;

      expect(type.fields.keys, ["shared"]);
      expect(container.read(_sourceProvider).document?.rootType, same(type));
    });
  });

  group("SelectionEditorSource mutations", () {
    test("fans out typed mutations and commits the accepted value", () async {
      final first = _identifier(
        "first",
        const StringValue("before"),
        mutation: const EditorMutationResult.applied(StringValue("accepted")),
      );
      final second = _identifier(
        "second",
        const StringValue("before"),
        mutation: const EditorMutationResult.applied(StringValue("accepted")),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);
      const path = DataPath.root;

      final result = container
          .read(_sourceProvider)
          .update(path, const StringValue("requested"));

      expect(
        (result as AppliedEditorMutation).value,
        const StringValue("accepted"),
      );
      expect(first.latest!.validatedPath, path);
      expect(first.latest!.validatedValue, const StringValue("requested"));
      expect(second.latest!.validatedPath, path);

      await container.read(_sourceProvider).flush();

      expect(first.latest!.latestCommit?.changedPaths, {path});
      expect(first.latest!.latestCommit?.expectedRevision, 1);
      expect(first.latest!.latestCommit?.localRevision, 1);
      expect(
        first.latest!.latestCommit?.rootValue,
        const StringValue("accepted"),
      );
      expect(second.latest!.latestCommit?.changedPaths, {path});
    });

    test("reports conflict when selections accept different values", () {
      final first = _identifier(
        "first",
        const StringValue("before"),
        mutation: const EditorMutationResult.applied(StringValue("first")),
      );
      final second = _identifier(
        "second",
        const StringValue("before"),
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
        const StringValue("before"),
        mutation: _invalidMutation("First invalid"),
      );
      final second = _identifier(
        "second",
        const StringValue("before"),
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
        const StringValue("before"),
        mutation: const EditorMutationResult.applied(StringValue("after")),
      );
      final second = _identifier(
        "second",
        const StringValue("before"),
        mutation: _invalidMutation("Rejected"),
      );
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier).selectAll([first, second]);

      final result = container
          .read(_sourceProvider)
          .update(DataPath.root, const StringValue("after"));

      expect(result, isA<InvalidEditorMutation>());
      expect(first.latest!.latestCommit, isNull);
      expect(second.latest!.latestCommit, isNull);
    });
  });
}
