import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring_facts.dart"
    as facts;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  for (final kind in ["named", "expected named Unfilled", "ordinary"]) {
    testWidgets(
      "direct $kind text preserves authored identity through edit and clear",
      (tester) async {
        final named = kind != "ordinary";
        final initial = kind == "expected named Unfilled"
            ? types.DataValue.unfilled
            : named
            ? types.DataValue.createNamed(
                actualType: _chapterTextType,
                payload: types.DataValue.wrapStringValue("old.chapter"),
              )
            : types.DataValue.wrapStringValue("old.chapter");
        final fixture = _fixture(
          fieldName: "chapter",
          initial: initial,
          namedText: named ? _chapterTextType : null,
        );
        await tester.pumpTestApp(
          child: Scaffold(
            body: AuthoredResourceEditor(
              resource: fixture.resource,
              draft: fixture.draft,
              catalog: fixture.catalog,
              role: catalog.PresentationRole.inspector,
              budget: expression.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextFormField), "new.chapter");
        await tester.pumpAndSettle();
        final expectedEdit = named
            ? types.DataValue.createNamed(
                actualType: _chapterTextType,
                payload: types.DataValue.wrapStringValue("new.chapter"),
              )
            : types.DataValue.wrapStringValue("new.chapter");
        expect(
          fixture.draft.resource(fixture.resource)?.authoredField("chapter"),
          expectedEdit,
        );
        expect(fixture.draft.intents, hasLength(1));
        final first =
            fixture.draft.intents.single
                as authoring.EditIntent_setValueWrapper;
        expect(first.value.at.resource, fixture.resource);
        expect(
          first.value.at.path,
          types.ValuePath(
            segments: [types.PathSegment.createField(name: "chapter")],
          ),
        );
        expect(first.value.value, expectedEdit);
        final expectation = fixture.draft
            .prepare()
            .expectations
            .whereType<facts.EditExpectation_valueWrapper>()
            .where((fact) => fact.value.at == first.value.at)
            .single;
        expect(expectation.value.expected, initial);
        await tester.enterText(find.byType(TextFormField), "");
        await tester.pumpAndSettle();
        final expectedClear = named
            ? types.DataValue.createNamed(
                actualType: _chapterTextType,
                payload: types.DataValue.wrapStringValue(""),
              )
            : types.DataValue.wrapStringValue("");
        expect(
          fixture.draft.resource(fixture.resource)?.authoredField("chapter"),
          expectedClear,
        );
        expect(fixture.draft.intents, hasLength(2));
        final clear =
            fixture.draft.intents.last as authoring.EditIntent_setValueWrapper;
        expect(clear.value.at, first.value.at);
        expect(clear.value.value, expectedClear);
      },
    );
  }

  for (final field in ["name", "chapter", "priority"]) {
    testWidgets(
      "inspector saves Unfilled $field with its exact authored expectation",
      (tester) async {
        final fixture = field == "priority"
            ? _numericFixture(
                generation: "catalog:1",
                snapshot: "realm:1",
                minimum: 0,
                fieldName: field,
                initial: types.DataValue.unfilled,
              )
            : _fixture(fieldName: field, initial: types.DataValue.unfilled);
        final submitted = <authoring.PreparedEdit>[];
        var latest = _snapshotOf(fixture.draft);
        Future<authoring.CommitPreparedEditResponse> commit(
          authoring.PreparedEdit edit,
        ) async {
          submitted.add(edit);
          final accepted = fixture.draft.fork();
          for (final intent
              in edit.intents.cast<authoring.EditIntent_setValueWrapper>()) {
            accepted.set(intent.value.at, intent.value.value);
          }
          latest = _snapshotOf(accepted);
          return authoring.CommitPreparedEditResponse.wrapResult(
            authoring.CommitResult.committed,
          );
        }

        final commands = AuthoredResourceCommands(
          commit: commit,
          previewTypeArguments: ({required resource, required requested}) =>
              throw UnimplementedError(),
          commitTypeArguments: (_) => throw UnimplementedError(),
          prepareCreation: (_) => throw UnimplementedError(),
          invokeCommand: ({required capabilityId, required payload}) async =>
              capability.CommandResult.unknown,
          watchSearch: (_) => const Stream.empty(),
          reload: () async {},
          openAutosave: _openAutosave(
            commit: commit,
            fetchCurrent: () async => latest,
          ),
        );
        await tester.pumpTestApp(
          child: Scaffold(
            body: AuthoredResourceInspection(
              resource: fixture.resource,
              draft: fixture.draft,
              catalog: fixture.catalog,
              commands: commands,
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextFormField),
          field == "priority" ? "3" : "new",
        );
        await tester.pump(AuthoredDraftAutosave.debounce);
        await tester.pumpAndSettle();
        expect(submitted, hasLength(1));
        final set =
            submitted.single.intents.single
                as authoring.EditIntent_setValueWrapper;
        expect(set.value.at.resource, fixture.resource);
        expect(
          set.value.at.path,
          types.ValuePath(
            segments: [types.PathSegment.createField(name: field)],
          ),
        );
        expect(
          set.value.value,
          field == "priority"
              ? types.DataValue.wrapInteger("3")
              : types.DataValue.wrapStringValue("new"),
        );
        final expected = submitted.single.expectations
            .whereType<facts.EditExpectation_valueWrapper>()
            .where((fact) => fact.value.at == set.value.at)
            .single;
        expect(expected.value.expected, types.DataValue.unfilled);
        expect(find.textContaining("changed"), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets("empty page graph receives the bounded editor workspace", (
    tester,
  ) async {
    final fixture = _emptyPageGraphFixture();
    final commands = AuthoredResourceCommands(
      commit: (_) => throw UnimplementedError(),
      previewTypeArguments: ({required resource, required requested}) =>
          throw UnimplementedError(),
      commitTypeArguments: (_) => throw UnimplementedError(),
      prepareCreation: (_) => throw UnimplementedError(),
      invokeCommand: ({required capabilityId, required payload}) async =>
          capability.CommandResult.unknown,
      watchSearch: (_) => const Stream.empty(),
      reload: () async {},
      openAutosave: _openAutosave(commit: (_) => throw UnimplementedError()),
    );

    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredResourceInspection(
          resource: fixture.resource,
          draft: fixture.draft,
          catalog: fixture.catalog,
          commands: commands,
          role: catalog.PresentationRole.editor,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Graph), findsOneWidget);
    final size = tester.getSize(find.byType(Graph));
    expect(size.width.isFinite, isTrue);
    expect(size.height.isFinite, isTrue);
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
  });

  testWidgets("graph roles preserve the one cell constraint", (tester) async {
    Future<void> pumpCard({
      required String title,
      required double width,
      bool requireTitle = false,
    }) async {
      final fixture = _fixture(title: title, requireTitle: requireTitle);
      await tester.pumpTestApp(
        child: Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: AuthoredResourceEditor(
                  resource: fixture.resource,
                  draft: fixture.draft,
                  catalog: fixture.catalog,
                  role: catalog.PresentationRole.graphNode,
                  budget: expression.EvaluationBudget(
                    maxSteps: 100,
                    maxCollectionItems: 100,
                  ),
                  enabled: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Icones), findsOneWidget);
    }

    await pumpCard(title: "", width: 48, requireTitle: true);
    expect(find.bySemanticsLabel("Presentation error"), findsOneWidget);
    for (var attempt = 0; attempt < 8; attempt++) {
      if (FocusManager.instance.primaryFocus?.debugLabel ==
          "Presentation error") {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      "Presentation error",
    );
    expect(find.text("Title must not be blank"), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Title must not be blank"), findsNothing);

    await pumpCard(title: "Quest", width: 48);
    expect(find.bySemanticsLabel("Presentation error"), findsNothing);
    await pumpCard(title: "Quest", width: 180);
    expect(find.text("Quest"), findsOneWidget);
  });

  testWidgets("editor roles keep full local diagnostic messages", (
    tester,
  ) async {
    final fixture = _fixture(title: "", requireTitle: true);
    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredResourceEditor(
          resource: fixture.resource,
          draft: fixture.draft,
          catalog: fixture.catalog,
          role: catalog.PresentationRole.editor,
          budget: expression.EvaluationBudget(
            maxSteps: 100,
            maxCollectionItems: 100,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Title must not be blank"), findsOneWidget);
    expect(find.bySemanticsLabel("Presentation error"), findsNothing);
  });

  testWidgets("selects catalog material and writes the authored draft", (
    tester,
  ) async {
    final fixture = _fixture();
    AuthoredDraft? changed;

    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: AuthoredResourceEditor(
            resource: fixture.resource,
            draft: fixture.draft,
            catalog: fixture.catalog,
            role: catalog.PresentationRole.editor,
            budget: expression.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
            onChanged: (draft) => changed = draft,
          ),
        ),
      ),
    );

    expect(find.text("Original"), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), "Changed");
    await tester.pump();

    expect(changed, same(fixture.draft));
    expect(
      fixture.draft
          .resource(fixture.resource)
          ?.authoredField("title")
          ?.authoredString,
      "Changed",
    );
    expect(fixture.draft.intents, hasLength(1));
    expect(
      fixture.draft.intents.single,
      isA<authoring.EditIntent_setValueWrapper>(),
    );
  });

  testWidgets(
    "inspection restores the catalog header and compact apply controls",
    (tester) async {
      final fixture = _fixture();
      final commands = AuthoredResourceCommands(
        commit: (_) => throw UnimplementedError(),
        previewTypeArguments: ({required resource, required requested}) =>
            throw UnimplementedError(),
        commitTypeArguments: (_) => throw UnimplementedError(),
        prepareCreation: (_) => throw UnimplementedError(),
        invokeCommand: ({required capabilityId, required payload}) async =>
            capability.CommandResult.unknown,
        watchSearch: (_) => const Stream.empty(),
        reload: () async {},
        openAutosave: _openAutosave(commit: (_) => throw UnimplementedError()),
      );

      await tester.pumpTestApp(
        child: Scaffold(
          body: AuthoredResourceInspection(
            resource: fixture.resource,
            draft: fixture.draft,
            catalog: fixture.catalog,
            commands: commands,
            commitPolicy: EditorCommitPolicy.applyResource,
          ),
        ),
      );

      expect(find.byKey(const ValueKey("message.header")), findsOneWidget);
      expect(find.byType(InspectorHeader), findsNothing);
      expect(find.text("Cancel"), findsNothing);
      expect(find.text("Apply"), findsNothing);

      await tester.enterText(find.byType(TextFormField), "Changed");
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey("message.header")),
          matching: find.text("Changed"),
        ),
        findsOneWidget,
      );
      expect(find.text("Cancel"), findsOneWidget);
      expect(find.text("Apply"), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey("message.header"))).dy,
        lessThan(tester.getTopLeft(find.byType(TextFormField)).dy),
      );
      expect(
        tester.getTopLeft(find.text("Apply")).dy,
        greaterThan(tester.getTopLeft(find.byType(TextFormField)).dy),
      );
    },
  );

  testWidgets("preparing after a catalog change applies the new local rule", (
    tester,
  ) async {
    final first = _numericFixture(
      generation: "catalog:1",
      snapshot: "realm:1",
      minimum: 1,
    );
    await tester.pumpTestApp(child: _numericEditor(first));
    await tester.enterText(find.byType(TextFormField), "3");
    await tester.pump();
    final evidence = first.draft.expectations.toList(growable: false);

    final second = _numericFixture(
      generation: "catalog:2",
      snapshot: "realm:2",
      minimum: 10,
    );
    final adoption = first.draft.rebaseOnto(second.draft);
    expect(adoption, isA<AuthoredDraftRebaseFailed>());
    final rebound = second.draft.fork();
    rebound.set(
      types.ValueLocation(
        resource: second.resource,
        path: types.ValuePath(
          segments: [types.PathSegment.createField(name: "repetitions")],
        ),
      ),
      types.DataValue.wrapInteger("3"),
    );

    await tester.pumpTestApp(
      child: _numericEditor((
        resource: second.resource,
        draft: rebound,
        catalog: second.catalog,
      )),
    );
    await tester.pump();

    expect(find.text("Must be at least 10"), findsOneWidget);
    expect(
      rebound
          .resource(second.resource)
          ?.authoredField("repetitions")
          ?.authoredInteger,
      BigInt.from(3),
    );
    expect(rebound.intents, hasLength(1));
    expect(first.draft.expectations, evidence);
    expect(rebound.generation, second.draft.generation);
  });

  testWidgets("required numeric input saves Unfilled and can be repaired", (
    tester,
  ) async {
    final fixture = _numericFixture(
      generation: "catalog:1",
      snapshot: "realm:1",
      minimum: 1,
    );
    await tester.pumpTestApp(child: _numericEditor(fixture));

    await tester.enterText(find.byType(TextFormField), "");
    await tester.pump();
    expect(
      fixture.draft.resource(fixture.resource)?.authoredField("repetitions"),
      types.DataValue.unfilled,
    );
    expect(fixture.draft.intents, hasLength(1));

    final empty = _numericFixture(
      generation: "catalog:1",
      snapshot: "realm:2",
      minimum: 1,
      initial: types.DataValue.unfilled,
    );
    await tester.pumpTestApp(child: _numericEditor(empty));
    await tester.enterText(find.byType(TextFormField), "7");
    await tester.pump();
    expect(
      empty.draft
          .resource(empty.resource)
          ?.authoredField("repetitions")
          ?.authoredInteger,
      BigInt.from(7),
    );
  });

  testWidgets("adopts a snapshot that arrives while a save is active", (
    tester,
  ) async {
    final first = _fixture();
    final completion = Completer<authoring.CommitPreparedEditResponse>();
    final adoption = Completer<authoring.AuthoringState>();
    final commands = AuthoredResourceCommands(
      commit: (_) => completion.future,
      previewTypeArguments: ({required resource, required requested}) =>
          throw UnimplementedError(),
      commitTypeArguments: (_) => throw UnimplementedError(),
      prepareCreation: (_) => throw UnimplementedError(),
      invokeCommand: ({required capabilityId, required payload}) async =>
          capability.CommandResult.unknown,
      watchSearch: (_) => const Stream.empty(),
      reload: () async {},
      openAutosave: _openAutosave(
        commit: (_) => completion.future,
        fetchCurrent: () => adoption.future,
      ),
    );

    Widget inspection(
      ({
        types.ResourceId resource,
        AuthoredDraft draft,
        CheckedEditorCatalog catalog,
      })
      fixture,
    ) => Builder(
      builder: (_) => Scaffold(
        body: AuthoredResourceInspection(
          resource: fixture.resource,
          draft: fixture.draft,
          catalog: fixture.catalog,
          commands: commands,
          role: catalog.PresentationRole.editor,
          commitPolicy: EditorCommitPolicy.applyResource,
        ),
      ),
    );

    var current = first;
    late StateSetter rebuild;
    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return inspection(current);
        },
      ),
    );
    await tester.enterText(find.byType(TextFormField), "Changed");
    await tester.pump();
    await tester.tap(find.text("Apply"));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final replacement = _fixture(snapshot: "realm:2", title: "Changed");
    rebuild(() => current = replacement);
    adoption.complete(_snapshotOf(replacement.draft));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completion.complete(
      authoring.CommitPreparedEditResponse.wrapResult(
        authoring.CommitResult.committed,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
      "Changed",
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets("ordinary edits autosave and retain the ordered edit tail", (
    tester,
  ) async {
    final first = _fixture();
    final firstResponse = Completer<authoring.CommitPreparedEditResponse>();
    final secondResponse = Completer<authoring.CommitPreparedEditResponse>();
    final snapshots = <String, Completer<authoring.AuthoringState>>{};
    var fetchCount = 1;
    final submitted = <authoring.PreparedEdit>[];
    Future<authoring.CommitPreparedEditResponse> commit(
      authoring.PreparedEdit edit,
    ) {
      submitted.add(edit);
      return submitted.length == 1
          ? firstResponse.future
          : secondResponse.future;
    }

    final commands = AuthoredResourceCommands(
      commit: commit,
      previewTypeArguments: ({required resource, required requested}) =>
          throw UnimplementedError(),
      commitTypeArguments: (_) => throw UnimplementedError(),
      prepareCreation: (_) => throw UnimplementedError(),
      invokeCommand: ({required capabilityId, required payload}) async =>
          capability.CommandResult.unknown,
      watchSearch: (_) => const Stream.empty(),
      reload: () async {},
      openAutosave: _openAutosave(
        commit: commit,
        fetchCurrent: () => snapshots
            .putIfAbsent("realm:${++fetchCount}", Completer.new)
            .future,
      ),
    );
    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredResourceInspection(
          resource: first.resource,
          draft: first.draft,
          catalog: first.catalog,
          commands: commands,
          role: catalog.PresentationRole.editor,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), "First");
    await tester.pump(AuthoredDraftAutosave.debounce);
    expect(submitted, hasLength(1));
    expect(submitted.single.intents, hasLength(1));
    expect(find.text("Apply"), findsNothing);
    expect(find.text("Cancel"), findsNothing);

    await tester.enterText(find.byType(TextFormField), "Second");
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);

    final second = _fixture(snapshot: "realm:2", title: "First");
    snapshots
        .putIfAbsent("realm:2", Completer.new)
        .complete(_snapshotOf(second.draft));
    firstResponse.complete(
      authoring.CommitPreparedEditResponse.wrapResult(
        authoring.CommitResult.committed,
      ),
    );
    await tester.pump(AuthoredDraftAutosave.debounce);
    await tester.pump();

    expect(submitted, hasLength(2));
    expect(submitted.last.catalog, second.draft.generation);
    expect(submitted.last.intents, hasLength(1));

    final third = _fixture(snapshot: "realm:3", title: "Second");
    snapshots
        .putIfAbsent("realm:3", Completer.new)
        .complete(_snapshotOf(third.draft));
    secondResponse.complete(
      authoring.CommitPreparedEditResponse.wrapResult(
        authoring.CommitResult.committed,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Saved"), findsOneWidget);
    expect(find.text("Second"), findsOneWidget);
  });

  testWidgets(
    "autosave retains text focus through staging and snapshot adoption",
    (tester) async {
      final first = _fixture(title: "");
      final adopted = {
        "realm:2": _fixture(snapshot: "realm:2", title: "book"),
        "realm:3": _fixture(snapshot: "realm:3", title: "books"),
      };
      var submissions = 0;
      Future<authoring.CommitPreparedEditResponse> commit(
        authoring.PreparedEdit _,
      ) async {
        submissions++;
        return authoring.CommitPreparedEditResponse.wrapResult(
          authoring.CommitResult.committed,
        );
      }

      final commands = AuthoredResourceCommands(
        commit: commit,
        previewTypeArguments: ({required resource, required requested}) =>
            throw UnimplementedError(),
        commitTypeArguments: (_) => throw UnimplementedError(),
        prepareCreation: (_) => throw UnimplementedError(),
        invokeCommand: ({required capabilityId, required payload}) async =>
            capability.CommandResult.unknown,
        watchSearch: (_) => const Stream.empty(),
        reload: () async {},
        openAutosave: _openAutosave(
          commit: commit,
          fetchCurrent: () => Future.value(
            _snapshotOf(adopted["realm:${submissions + 1}"]!.draft),
          ),
        ),
      );
      await tester.pumpTestApp(
        child: Scaffold(
          body: AuthoredResourceInspection(
            resource: first.resource,
            draft: first.draft,
            catalog: first.catalog,
            commands: commands,
            role: catalog.PresentationRole.editor,
          ),
        ),
      );

      final field = find.byType(TextFormField);
      await tester.showKeyboard(field);
      for (final text in ["b", "bo", "boo", "book"]) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        await tester.pump();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        "book",
      );
      expect(submissions, 0);

      await tester.pump(AuthoredDraftAutosave.debounce);
      await tester.pumpAndSettle();
      expect(submissions, 1);

      await tester.showKeyboard(field);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: "books",
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.pump(AuthoredDraftAutosave.debounce);
      await tester.pumpAndSettle();

      expect(submissions, 2);
      expect(find.text("Saved"), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        "books",
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    },
  );

  testWidgets(
    "an uncertain save keeps local edits until choosing current values",
    (tester) async {
      var submissions = 0;
      final first = _fixture();
      final recovered = _fixture(snapshot: "realm:4", title: "After");
      Future<authoring.CommitPreparedEditResponse> commit(
        authoring.PreparedEdit _,
      ) async {
        submissions++;
        if (submissions == 1) throw StateError("The save response timed out");
        return authoring.CommitPreparedEditResponse.wrapResult(
          authoring.CommitResult.committed,
        );
      }

      final commands = AuthoredResourceCommands(
        commit: commit,
        previewTypeArguments: ({required resource, required requested}) =>
            throw UnimplementedError(),
        commitTypeArguments: (_) => throw UnimplementedError(),
        prepareCreation: (_) => throw UnimplementedError(),
        invokeCommand: ({required capabilityId, required payload}) async =>
            capability.CommandResult.unknown,
        watchSearch: (_) => const Stream.empty(),
        reload: () async {},
        openAutosave: _openAutosave(
          commit: commit,
          fetchCurrent: () => Future.value(_snapshotOf(recovered.draft)),
        ),
      );
      var current = first;
      late StateSetter rebuild;
      await tester.pumpTestApp(
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Scaffold(
              body: AuthoredResourceInspection(
                resource: current.resource,
                draft: current.draft,
                catalog: current.catalog,
                commands: commands,
                role: catalog.PresentationRole.editor,
              ),
            );
          },
        ),
      );

      await tester.enterText(find.byType(TextFormField), "First");
      await tester.pump(AuthoredDraftAutosave.debounce);
      await tester.pump();
      expect(submissions, 1);
      expect(find.text("Use latest"), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), "Second");
      await tester.pump(AuthoredDraftAutosave.debounce);
      expect(submissions, 1);

      final latest = _fixture(snapshot: "realm:3", title: "Latest");
      rebuild(() => current = latest);
      await tester.pump();
      await tester.tap(find.text("Use latest"));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
        "Latest",
      );
      expect(submissions, 1);

      await tester.enterText(find.byType(TextFormField), "After");
      await tester.pump(AuthoredDraftAutosave.debounce);
      await tester.pumpAndSettle();

      expect(submissions, 2);
      expect(find.text("Saved"), findsOneWidget);
    },
  );

  testWidgets("concurrent inspections own independent edit drafts", (
    tester,
  ) async {
    final fixture = _fixture();
    final commands = AuthoredResourceCommands(
      commit: (_) => throw UnimplementedError(),
      previewTypeArguments: ({required resource, required requested}) =>
          throw UnimplementedError(),
      commitTypeArguments: (_) => throw UnimplementedError(),
      prepareCreation: (_) => throw UnimplementedError(),
      invokeCommand: ({required capabilityId, required payload}) async =>
          capability.CommandResult.unknown,
      watchSearch: (_) => const Stream.empty(),
      reload: () async {},
      openAutosave: _openAutosave(commit: (_) => throw UnimplementedError()),
    );
    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: Row(
            children: [
              for (var index = 0; index < 2; index++)
                Expanded(
                  child: AuthoredResourceInspection(
                    resource: fixture.resource,
                    draft: fixture.draft,
                    catalog: fixture.catalog,
                    commands: commands,
                    role: catalog.PresentationRole.editor,
                    commitPolicy: EditorCommitPolicy.applyResource,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, "First edit");
    await tester.pumpAndSettle();

    expect(
      fixture.draft
          .resource(fixture.resource)
          ?.authoredField("title")
          ?.authoredString,
      "Original",
    );
    expect(fixture.draft.intents, isEmpty);
    expect(
      tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .last
          .initialValue,
      "Original",
    );
  });
}

AuthoredDraftAutosave Function({
  required types.ResourceId resource,
  required AuthoredDraft baseline,
  EditorCommitPolicy policy,
})
_openAutosave({
  required Future<authoring.CommitPreparedEditResponse> Function(
    authoring.PreparedEdit edit,
  )
  commit,
  Future<authoring.AuthoringState> Function()? fetchCurrent,
}) =>
    ({
      required resource,
      required baseline,
      policy = EditorCommitPolicy.autosaveChanges,
    }) => AuthoredDraftAutosave(
      resource: resource,
      baseline: baseline,
      policy: policy,
      commit: commit,
      fetchCurrent:
          fetchCurrent ??
          () => Future.error(
            StateError("No current values were configured for this test"),
          ),
      reload: () async {},
      onSettled: () {},
    );

authoring.AuthoringState _snapshotOf(AuthoredDraft draft) =>
    authoring.AuthoringState(
      generation: draft.generation,
      resources: [
        for (final resource in draft.resources.entries)
          authoring.AuthoringResource(
            id: resource.key,
            definition: catalog.ResourceDefinitionId.defaultInstance,
            content: resource.value,
          ),
      ],
      links: draft.links,
      findings: const [],
    );

({types.ResourceId resource, AuthoredDraft draft, CheckedEditorCatalog catalog})
_emptyPageGraphFixture() {
  final generation = types.CatalogGeneration(value: "catalog:page");
  final definition = types.TypeDefinitionId(
    typeId: types.TypeId.createQualified(
      namespace: "test",
      name: "SequencePage",
    ),
    revision: 1,
  );
  final presentationId = types.PresentationId(
    namespace: "test",
    name: "sequence.editor",
  );
  final target = catalog.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: definition,
            parameters: const [],
            representation: types.RepresentationTemplate.createRecord(
              fields: const [],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: [
        catalog.PresentationDescriptor(
          id: presentationId,
          owner: types.DeclarationOwner.defaultInstance,
          target: target,
          roles: [catalog.PresentationRole.editor],
          priority: 0,
        ),
      ],
      presentationMaterials: [
        catalog.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: catalog.PresentationRole.editor,
          layout: presentation.PresentationNode(
            nodeId: "generated.root",
            properties: presentation.PresentationProperties.defaultInstance,
            element: presentation.PresentationElement.wrapChildren(
              presentation.ChildrenElement.createColumn(
                children: [
                  presentation.AxisChild.wrapFixed(
                    presentation.PresentationNode(
                      nodeId: "sequence.graph",
                      properties:
                          presentation.PresentationProperties.defaultInstance,
                      element: presentation.PresentationElement.createPageGraph(
                        control: presentation.BoundControl(
                          binding: binding.BindingRef(
                            bindingId: configuredValueBindingId,
                            path: types.ValuePath(
                              segments: [
                                types.PathSegment.createField(name: "elements"),
                              ],
                            ),
                          ),
                          label: null,
                          description: null,
                          prefix: null,
                          semanticLabel: null,
                        ),
                        direction: presentation.PageGraphDirection.leftToRight,
                      ),
                      header: null,
                    ),
                  ),
                ],
                layout: presentation.AxisChildrenLayout(
                  spacing: 0,
                  mainAxisAlignment: presentation.MainAxisAlignment.start,
                  crossAxisAlignment: presentation.CrossAxisAlignment.start,
                ),
              ),
            ),
            header: null,
          ),
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: types.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
      ],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final resource = types.ResourceId(value: "page:empty");
  final record = types.AuthoringRecord(
    configuration: types.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    ),
    fields: [
      types.FieldValue(name: "elements", value: types.DataValue.unfilled),
    ],
  );
  final draft = AuthoredDraft(
    generation: generation,
    resources: [
      authoring.AuthoringResource(
        id: resource,
        definition: catalog.ResourceDefinitionId(value: "typewriter.page"),
        content: record,
      ),
    ],
    links: const [],
    catalog: checked,
  );
  return (resource: resource, draft: draft, catalog: checked);
}

Widget _numericEditor(
  ({
    types.ResourceId resource,
    AuthoredDraft draft,
    CheckedEditorCatalog catalog,
  })
  fixture,
) => Builder(
  builder: (_) => Scaffold(
    body: AuthoredResourceEditor(
      resource: fixture.resource,
      draft: fixture.draft,
      catalog: fixture.catalog,
      role: catalog.PresentationRole.inspector,
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
    ),
  ),
);

({types.ResourceId resource, AuthoredDraft draft, CheckedEditorCatalog catalog})
_numericFixture({
  required String generation,
  required String snapshot,
  required int minimum,
  types.DataValue? initial,
  String fieldName = "repetitions",
}) {
  final catalogGeneration = types.CatalogGeneration(value: generation);
  final definition = types.TypeDefinitionId(
    typeId: types.TypeId.createQualified(namespace: "test", name: "Repeating"),
    revision: 1,
  );
  final presentationId = types.PresentationId(
    namespace: "test",
    name: "repeating.inspector",
  );
  final ruleOrigin = types.RuleOrigin(owner: definition, ordinal: 0);
  final ruleId = types.RuleId(origin: ruleOrigin, localIndex: 0);
  final configured = types.ExpressionBindingId(value: "configured_value");
  final target = catalog.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  final path = types.ValuePath(
    segments: [types.PathSegment.createField(name: fieldName)],
  );
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
      generation: catalogGeneration,
      types: [
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: definition,
            parameters: const [],
            representation: types.RepresentationTemplate.createRecord(
              fields: [
                types.FieldDeclaration(
                  owner: types.FieldOwner(
                    definition: definition,
                    name: fieldName,
                  ),
                  type: types.TypeTemplate.wrapScalar(
                    types.ScalarKind.createInteger(
                      width: types.IntegerWidth.signedThirtyTwo,
                    ),
                  ),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: [
            catalog.EffectiveFieldTemplate(
              key: fieldName,
              owner: types.FieldOwner(definition: definition, name: fieldName),
              type: types.TypeTemplate.wrapScalar(
                types.ScalarKind.createInteger(
                  width: types.IntegerWidth.signedThirtyTwo,
                ),
              ),
              rules: [ruleId],
            ),
          ],
          ancestorTemplates: const [],
        ),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: [
        catalog.PresentationDescriptor(
          id: presentationId,
          owner: types.DeclarationOwner.defaultInstance,
          target: target,
          roles: [catalog.PresentationRole.inspector],
          priority: 0,
        ),
      ],
      presentationMaterials: [
        catalog.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: catalog.PresentationRole.inspector,
          layout: presentation.PresentationNode(
            nodeId: fieldName,
            properties: presentation.PresentationProperties.defaultInstance,
            element: presentation.PresentationElement.wrapNumericInput(
              presentation.BoundControl(
                binding: binding.BindingRef(
                  bindingId: configuredValueBindingId,
                  path: path,
                ),
                label: null,
                description: null,
                prefix: null,
                semanticLabel: null,
              ),
            ),
            header: null,
          ),
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: types.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
      ],
      configuration: [
        catalog.ConfigurationRecipe(
          origin: ruleOrigin,
          relativePath: types.RelativeFieldPattern(
            segments: [types.FieldPatternSegment.createField(name: fieldName)],
          ),
          representationCondition: catalog.RepresentationKind.integer,
          rules: [
            catalog.OwnedRule(
              id: ruleId,
              descriptor: catalog.RuleDescriptor(
                predicate: expression.ExpressionNode.createCall(
                  operation: types.OperationId(
                    value: "typewriter.rule.minimum",
                  ),
                  arguments: [
                    expression.ExpressionNode.createRead(
                      binding: configured,
                      path: types.ValuePath(segments: const []),
                    ),
                    expression.ExpressionNode.wrapLiteral(
                      types.DataValue.wrapInteger(minimum.toString()),
                    ),
                    expression.ExpressionNode.wrapLiteral(
                      types.DataValue.wrapBoolean(true),
                    ),
                  ],
                ),
              ),
              diagnostic: diagnostic.DiagnosticTemplate(
                code: "minimum",
                message: "Must be at least $minimum",
                severity: diagnostic.DiagnosticSeverity.error,
                targets: const [],
              ),
            ),
          ],
        ),
      ],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final resource = types.ResourceId(value: "repeating:one");
  final record = types.AuthoringRecord(
    configuration: types.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    ),
    fields: [
      types.FieldValue(
        name: fieldName,
        value: initial ?? types.DataValue.wrapInteger("2"),
      ),
    ],
  );
  return (
    resource: resource,
    catalog: checked,
    draft: AuthoredDraft(
      generation: catalogGeneration,
      resources: [
        authoring.AuthoringResource(
          id: resource,
          definition: catalog.ResourceDefinitionId(value: "test.repeating"),
          content: record,
        ),
      ],
      links: const [],
      catalog: checked,
    ),
  );
}

({types.ResourceId resource, AuthoredDraft draft, CheckedEditorCatalog catalog})
_fixture({
  String snapshot = "realm:1",
  String title = "Original",
  bool requireTitle = false,
  String fieldName = "title",
  types.DataValue? initial,
  types.NamedTypeUse? namedText,
}) {
  final generation = types.CatalogGeneration(value: "catalog:1");
  final fieldType = namedText == null
      ? types.TypeTemplate.wrapScalar(types.ScalarKind.text)
      : types.TypeTemplate.createNamed(
          definition: namedText.definition,
          arguments: const [],
        );
  final definition = types.TypeDefinitionId(
    typeId: types.TypeId.wrapQualified(
      types.QualifiedTypeId(namespace: "test", name: "Message"),
    ),
    revision: 1,
  );
  final presentationId = types.PresentationId(
    namespace: "test",
    name: "message.editor",
  );
  final ruleOrigin = types.RuleOrigin(owner: definition, ordinal: 0);
  final titleRule = types.RuleId(origin: ruleOrigin, localIndex: 0);
  final target = catalog.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  final layout = presentation.PresentationNode(
    nodeId: "message.title",
    properties: presentation.PresentationProperties.defaultInstance,
    element: presentation.PresentationElement.createTextInput(
      control: presentation.BoundControl(
        binding: binding.BindingRef(
          bindingId: configuredValueBindingId,
          path: types.ValuePath(
            segments: [types.PathSegment.createField(name: fieldName)],
          ),
        ),
        label: null,
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      multiline: false,
      placeholder: null,
      inputFormatters: const [],
    ),
    header: null,
  );
  final headerLayout = presentation.PresentationNode(
    nodeId: "message.header",
    properties: presentation.PresentationProperties.defaultInstance,
    element: presentation.PresentationElement.createText(
      value: expression.ExpressionNode.createRead(
        binding: configuredValueBindingId,
        path: types.ValuePath(
          segments: [types.PathSegment.createField(name: fieldName)],
        ),
      ),
      color: null,
      fontSize: null,
      fontWeight: null,
      fontItalic: null,
      fontOpticalSize: null,
      fontSlant: null,
      fontWidth: null,
      textAlignment: null,
      lineHeight: null,
      letterSpacing: null,
      decoration: null,
      semanticLabel: null,
      paragraph: presentation.TextParagraph.defaultInstance,
    ),
    header: null,
  );
  final graphLayout = presentation.PresentationNode(
    nodeId: "message.graph",
    properties: presentation.PresentationProperties.defaultInstance,
    element: presentation.PresentationElement.createAdaptiveLeading(
      leading: presentation.PresentationNode(
        nodeId: "message.graph.icon.color",
        properties: presentation.PresentationProperties.defaultInstance,
        element: presentation.PresentationElement.createContainer(
          child: presentation.PresentationNode(
            nodeId: "message.graph.icon.padding",
            properties: presentation.PresentationProperties.defaultInstance,
            element: presentation.PresentationElement.createPadding(
              child: presentation.PresentationNode(
                nodeId: "message.graph.icon",
                properties: presentation.PresentationProperties.defaultInstance,
                element: presentation.PresentationElement.createIcon(
                  name: expression.ExpressionNode.wrapLiteral(
                    types.DataValue.wrapStringValue(
                      '<svg xmlns="http://www.w3.org/2000/svg" '
                      'viewBox="0 0 24 24">'
                      ' <path d="M4 4h16v16H4z"/></svg>',
                    ),
                  ),
                  semanticLabel: expression.ExpressionNode.wrapLiteral(
                    types.DataValue.wrapStringValue("Tag"),
                  ),
                  color: null,
                  size: null,
                ),
                header: null,
              ),
              top: 6,
              start: 6,
              end: 6,
              bottom: 6,
            ),
            header: null,
          ),
          border: null,
          backgroundColor: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapInteger("4288585374"),
          ),
          radius: presentation.PresentationRadius.none,
        ),
        header: null,
      ),
      center: headerLayout,
      suffix: null,
      padding: presentation.PresentationInsets.wrapAll(8),
      compactPadding: presentation.PresentationInsets.wrapAll(4),
      gap: 12,
      minimumCenterWidth: 80,
    ),
    header: null,
  );
  final generatedGraphLayout = presentation.PresentationNode(
    nodeId: "message.graph.root",
    properties: presentation.PresentationProperties.defaultInstance,
    element: presentation.PresentationElement.wrapChildren(
      presentation.ChildrenElement.createColumn(
        children: [presentation.AxisChild.wrapFixed(graphLayout)],
        layout: presentation.AxisChildrenLayout(
          spacing: 0,
          mainAxisAlignment: presentation.MainAxisAlignment.start,
          crossAxisAlignment: presentation.CrossAxisAlignment.start,
        ),
      ),
    ),
    header: null,
  );
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        if (namedText != null)
          catalog.PublishedType(
            display: null,
            definition: types.TypeDefinition(
              id: namedText.definition,
              parameters: const [],
              representation: types.RepresentationTemplate.createScalar(
                kind: types.ScalarKind.text,
              ),
              parents: const [],
            ),
            status: catalog.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: const [],
          ),
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: definition,
            parameters: const [],
            representation: types.RepresentationTemplate.createRecord(
              fields: [
                types.FieldDeclaration(
                  owner: types.FieldOwner(
                    definition: definition,
                    name: fieldName,
                  ),
                  type: fieldType,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: [
            catalog.EffectiveFieldTemplate(
              key: fieldName,
              owner: types.FieldOwner(definition: definition, name: fieldName),
              type: fieldType,
              rules: requireTitle ? [titleRule] : const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: [
        catalog.PresentationDescriptor(
          id: presentationId,
          owner: types.DeclarationOwner.defaultInstance,
          target: target,
          roles: [
            catalog.PresentationRole.editor,
            catalog.PresentationRole.inspector,
            catalog.PresentationRole.inspectorHeader,
            catalog.PresentationRole.graphNode,
          ],
          priority: 0,
        ),
      ],
      presentationMaterials: [
        catalog.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: catalog.PresentationRole.editor,
          layout: layout,
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: types.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
        catalog.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: catalog.PresentationRole.inspector,
          layout: layout,
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: types.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
        catalog.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: catalog.PresentationRole.inspectorHeader,
          layout: headerLayout,
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: types.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
        catalog.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: catalog.PresentationRole.graphNode,
          layout: generatedGraphLayout,
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: types.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
      ],
      configuration: requireTitle
          ? [
              catalog.ConfigurationRecipe(
                origin: ruleOrigin,
                relativePath: types.RelativeFieldPattern(
                  segments: [
                    types.FieldPatternSegment.createField(name: fieldName),
                  ],
                ),
                representationCondition: catalog.RepresentationKind.text,
                rules: [
                  catalog.OwnedRule(
                    id: titleRule,
                    descriptor: catalog.RuleDescriptor(
                      predicate: expression.ExpressionNode.createCall(
                        operation: types.OperationId(
                          value: "typewriter.rule.nonBlank",
                        ),
                        arguments: [
                          expression.ExpressionNode.createRead(
                            binding: configuredValueBindingId,
                            path: types.ValuePath(segments: const []),
                          ),
                        ],
                      ),
                    ),
                    diagnostic: diagnostic.DiagnosticTemplate(
                      code: "non_blank",
                      message: "Title must not be blank",
                      severity: diagnostic.DiagnosticSeverity.error,
                      targets: const [],
                    ),
                  ),
                ],
              ),
            ]
          : const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final resource = types.ResourceId(value: "message:one");
  final record = types.AuthoringRecord(
    configuration: types.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    ),
    fields: [
      types.FieldValue(
        name: fieldName,
        value: initial ?? types.DataValue.wrapStringValue(title),
      ),
    ],
  );
  final draft = AuthoredDraft(
    generation: generation,
    resources: [
      authoring.AuthoringResource(
        id: resource,
        definition: catalog.ResourceDefinitionId(value: "test.message"),
        content: record,
      ),
    ],
    links: const [],
    catalog: checked,
  );
  return (resource: resource, draft: draft, catalog: checked);
}

final _chapterTextType = types.NamedTypeUse(
  definition: types.TypeDefinitionId(
    typeId: types.TypeId.createQualified(
      namespace: "test",
      name: "ChapterPath",
    ),
    revision: 1,
  ),
  arguments: const [],
);
