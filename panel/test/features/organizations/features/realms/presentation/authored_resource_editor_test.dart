import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  for (final kind in ["named", "expected named Unfilled", "ordinary"]) {
    testWidgets(
      "direct $kind text preserves authored identity through edit and clear",
      (tester) async {
        final named = kind != "ordinary";
        final initial = kind == "expected named Unfilled"
            ? skir.DataValue.unfilled
            : named
            ? skir.DataValue.createNamed(
                actualType: _chapterTextType,
                payload: skir.DataValue.wrapStringValue("old.chapter"),
              )
            : skir.DataValue.wrapStringValue("old.chapter");
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
              role: skir.PresentationRole.inspector,
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextFormField), "new.chapter");
        await tester.pumpAndSettle();
        final expectedEdit = named
            ? skir.DataValue.createNamed(
                actualType: _chapterTextType,
                payload: skir.DataValue.wrapStringValue("new.chapter"),
              )
            : skir.DataValue.wrapStringValue("new.chapter");
        expect(
          fixture.draft.resource(fixture.resource)?.authoredField("chapter"),
          expectedEdit,
        );
        expect(fixture.draft.intents, hasLength(1));
        final first =
            fixture.draft.intents.single as skir.EditIntent_setValueWrapper;
        expect(first.value.at.resource, fixture.resource);
        expect(
          first.value.at.path,
          skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "chapter")],
          ),
        );
        expect(first.value.value, expectedEdit);
        final expectation = fixture.draft
            .prepare()
            .expectations
            .whereType<skir.EditExpectation_valueWrapper>()
            .where((fact) => fact.value.at == first.value.at)
            .single;
        expect(expectation.value.expected, initial);
        await tester.enterText(find.byType(TextFormField), "");
        await tester.pumpAndSettle();
        final expectedClear = named
            ? skir.DataValue.createNamed(
                actualType: _chapterTextType,
                payload: skir.DataValue.wrapStringValue(""),
              )
            : skir.DataValue.wrapStringValue("");
        expect(
          fixture.draft.resource(fixture.resource)?.authoredField("chapter"),
          expectedClear,
        );
        expect(fixture.draft.intents, hasLength(2));
        final clear =
            fixture.draft.intents.last as skir.EditIntent_setValueWrapper;
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
                initial: skir.DataValue.unfilled,
              )
            : _fixture(fieldName: field, initial: skir.DataValue.unfilled);
        final submitted = <skir.PreparedEdit>[];
        var latest = _snapshotOf(fixture.draft);
        Future<skir.CommitPreparedEditResponse> commit(
          skir.PreparedEdit edit,
        ) async {
          submitted.add(edit);
          final accepted = fixture.draft.fork();
          for (final intent
              in edit.intents.cast<skir.EditIntent_setValueWrapper>()) {
            accepted.set(intent.value.at, intent.value.value);
          }
          latest = _snapshotOf(accepted);
          return skir.CommitPreparedEditResponse.wrapResult(
            skir.CommitResult.committed,
          );
        }

        final commands = AuthoredResourceCommands(
          commit: commit,
          previewTypeArguments: ({required resource, required requested}) =>
              throw UnimplementedError(),
          commitTypeArguments: (_) => throw UnimplementedError(),
          prepareCreation: (_) => throw UnimplementedError(),
          invokeCommand: ({required capabilityId, required payload}) async =>
              skir.CommandResult.unknown,
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
            submitted.single.intents.single as skir.EditIntent_setValueWrapper;
        expect(set.value.at.resource, fixture.resource);
        expect(
          set.value.at.path,
          skir.ValuePath(segments: [skir.PathSegment.createField(name: field)]),
        );
        expect(
          set.value.value,
          field == "priority"
              ? skir.DataValue.wrapInteger("3")
              : skir.DataValue.wrapStringValue("new"),
        );
        final expected = submitted.single.expectations
            .whereType<skir.EditExpectation_valueWrapper>()
            .where((fact) => fact.value.at == set.value.at)
            .single;
        expect(expected.value.expected, skir.DataValue.unfilled);
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
          skir.CommandResult.unknown,
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
          role: skir.PresentationRole.editor,
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
                  role: skir.PresentationRole.graphNode,
                  budget: skir.EvaluationBudget(
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
          role: skir.PresentationRole.editor,
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
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
            role: skir.PresentationRole.editor,
            budget: skir.EvaluationBudget(
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
      isA<skir.EditIntent_setValueWrapper>(),
    );
  });

  testWidgets(
    "inspection composes identity and retains compact apply controls",
    (tester) async {
      final fixture = _fixture();
      final commands = AuthoredResourceCommands(
        commit: (_) => throw UnimplementedError(),
        previewTypeArguments: ({required resource, required requested}) =>
            throw UnimplementedError(),
        commitTypeArguments: (_) => throw UnimplementedError(),
        prepareCreation: (_) => throw UnimplementedError(),
        invokeCommand: ({required capabilityId, required payload}) async =>
            skir.CommandResult.unknown,
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
    final rebound = second.draft.fork()
      ..set(
        skir.ValueLocation(
          resource: second.resource,
          path: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "repetitions")],
          ),
        ),
        skir.DataValue.wrapInteger("3"),
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
      skir.DataValue.unfilled,
    );
    expect(fixture.draft.intents, hasLength(1));

    final empty = _numericFixture(
      generation: "catalog:1",
      snapshot: "realm:2",
      minimum: 1,
      initial: skir.DataValue.unfilled,
    );
    await tester.pumpTestApp(child: _numericEditor(empty));
    await tester.enterText(find.byType(TextFormField), "7");
    await tester.pumpAndSettle();
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
    final completion = Completer<skir.CommitPreparedEditResponse>();
    final adoption = Completer<skir.AuthoringState>();
    final commands = AuthoredResourceCommands(
      commit: (_) => completion.future,
      previewTypeArguments: ({required resource, required requested}) =>
          throw UnimplementedError(),
      commitTypeArguments: (_) => throw UnimplementedError(),
      prepareCreation: (_) => throw UnimplementedError(),
      invokeCommand: ({required capabilityId, required payload}) async =>
          skir.CommandResult.unknown,
      watchSearch: (_) => const Stream.empty(),
      reload: () async {},
      openAutosave: _openAutosave(
        commit: (_) => completion.future,
        fetchCurrent: () => adoption.future,
      ),
    );

    Widget inspection(
      ({
        skir.ResourceId resource,
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
          role: skir.PresentationRole.editor,
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
      skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
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
    final firstResponse = Completer<skir.CommitPreparedEditResponse>();
    final secondResponse = Completer<skir.CommitPreparedEditResponse>();
    final snapshots = <String, Completer<skir.AuthoringState>>{};
    var fetchCount = 1;
    final submitted = <skir.PreparedEdit>[];
    Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) {
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
          skir.CommandResult.unknown,
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
          role: skir.PresentationRole.editor,
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
      skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
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
      skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
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
      Future<skir.CommitPreparedEditResponse> commit(
        skir.PreparedEdit _,
      ) async {
        submissions++;
        return skir.CommitPreparedEditResponse.wrapResult(
          skir.CommitResult.committed,
        );
      }

      final commands = AuthoredResourceCommands(
        commit: commit,
        previewTypeArguments: ({required resource, required requested}) =>
            throw UnimplementedError(),
        commitTypeArguments: (_) => throw UnimplementedError(),
        prepareCreation: (_) => throw UnimplementedError(),
        invokeCommand: ({required capabilityId, required payload}) async =>
            skir.CommandResult.unknown,
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
            role: skir.PresentationRole.editor,
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
      Future<skir.CommitPreparedEditResponse> commit(
        skir.PreparedEdit _,
      ) async {
        submissions++;
        if (submissions == 1) throw StateError("The save response timed out");
        return skir.CommitPreparedEditResponse.wrapResult(
          skir.CommitResult.committed,
        );
      }

      final commands = AuthoredResourceCommands(
        commit: commit,
        previewTypeArguments: ({required resource, required requested}) =>
            throw UnimplementedError(),
        commitTypeArguments: (_) => throw UnimplementedError(),
        prepareCreation: (_) => throw UnimplementedError(),
        invokeCommand: ({required capabilityId, required payload}) async =>
            skir.CommandResult.unknown,
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
                role: skir.PresentationRole.editor,
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
          skir.CommandResult.unknown,
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
                    role: skir.PresentationRole.editor,
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
  required skir.ResourceId resource,
  required AuthoredDraft baseline,
  EditorCommitPolicy policy,
})
_openAutosave({
  required Future<skir.CommitPreparedEditResponse> Function(
    skir.PreparedEdit edit,
  )
  commit,
  Future<skir.AuthoringState> Function()? fetchCurrent,
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

skir.AuthoringState _snapshotOf(AuthoredDraft draft) => skir.AuthoringState(
  generation: draft.generation,
  resources: [
    for (final resource in draft.resources.entries)
      skir.AuthoringResource(
        id: resource.key,
        definition: skir.ResourceDefinitionId.defaultInstance,
        content: resource.value,
      ),
  ],
  links: draft.links,
  findings: const [],
);

({skir.ResourceId resource, AuthoredDraft draft, CheckedEditorCatalog catalog})
_emptyPageGraphFixture() {
  final generation = skir.CatalogGeneration(value: "catalog:page");
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "test",
      name: "SequencePage",
    ),
    revision: 1,
  );
  final presentationId = skir.PresentationId(
    namespace: "test",
    name: "sequence.editor",
  );
  final target = skir.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: definition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: const [],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: [
        skir.PresentationDescriptor(
          id: presentationId,
          owner: skir.DeclarationOwner.defaultInstance,
          target: target,
          roles: [skir.PresentationRole.editor],
          priority: 0,
        ),
      ],
      presentationMaterials: [
        skir.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: skir.PresentationRole.editor,
          layout: skir.PresentationNode(
            nodeId: "generated.root",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.wrapChildren(
              skir.ChildrenElement.createColumn(
                children: [
                  skir.AxisChild.wrapFixed(
                    skir.PresentationNode(
                      nodeId: "sequence.graph",
                      properties: skir.PresentationProperties.defaultInstance,
                      element: skir.PresentationElement.createPageGraph(
                        control: skir.BoundControl(
                          binding: skir.BindingRef(
                            bindingId: configuredValueBindingId,
                            path: skir.ValuePath(
                              segments: [
                                skir.PathSegment.createField(name: "elements"),
                              ],
                            ),
                          ),
                          label: null,
                          description: null,
                          prefix: null,
                          semanticLabel: null,
                        ),
                        direction: skir.PageGraphDirection.leftToRight,
                      ),
                      header: null,
                    ),
                  ),
                ],
                layout: skir.AxisChildrenLayout(
                  spacing: 0,
                  mainAxisAlignment: skir.MainAxisAlignment.start,
                  crossAxisAlignment: skir.CrossAxisAlignment.start,
                ),
              ),
            ),
            header: null,
          ),
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: skir.TypeTemplate.createNamed(
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
  final resource = skir.ResourceId(value: "page:empty");
  final record = skir.AuthoringRecord(
    configuration: skir.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    ),
    fields: [skir.FieldValue(name: "elements", value: skir.DataValue.unfilled)],
  );
  final draft = AuthoredDraft(
    generation: generation,
    resources: [
      skir.AuthoringResource(
        id: resource,
        definition: skir.ResourceDefinitionId(value: "typewriter.page"),
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
    skir.ResourceId resource,
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
      role: skir.PresentationRole.inspector,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    ),
  ),
);

({skir.ResourceId resource, AuthoredDraft draft, CheckedEditorCatalog catalog})
_numericFixture({
  required String generation,
  required String snapshot,
  required int minimum,
  skir.DataValue? initial,
  String fieldName = "repetitions",
}) {
  final catalogGeneration = skir.CatalogGeneration(value: generation);
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Repeating"),
    revision: 1,
  );
  final presentationId = skir.PresentationId(
    namespace: "test",
    name: "repeating.inspector",
  );
  final ruleOrigin = skir.RuleOrigin(owner: definition, ordinal: 0);
  final ruleId = skir.RuleId(origin: ruleOrigin, localIndex: 0);
  final configured = skir.ExpressionBindingId(value: "configured_value");
  final target = skir.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  final path = skir.ValuePath(
    segments: [skir.PathSegment.createField(name: fieldName)],
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: catalogGeneration,
      types: [
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: definition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: skir.FieldOwner(
                    definition: definition,
                    name: fieldName,
                  ),
                  type: skir.TypeTemplate.wrapScalar(
                    skir.ScalarKind.createInteger(
                      width: skir.IntegerWidth.signedThirtyTwo,
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
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: fieldName,
              owner: skir.FieldOwner(definition: definition, name: fieldName),
              type: skir.TypeTemplate.wrapScalar(
                skir.ScalarKind.createInteger(
                  width: skir.IntegerWidth.signedThirtyTwo,
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
        skir.PresentationDescriptor(
          id: presentationId,
          owner: skir.DeclarationOwner.defaultInstance,
          target: target,
          roles: [skir.PresentationRole.inspector],
          priority: 0,
        ),
      ],
      presentationMaterials: [
        skir.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: skir.PresentationRole.inspector,
          layout: skir.PresentationNode(
            nodeId: fieldName,
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.wrapNumericInput(
              skir.BoundControl(
                binding: skir.BindingRef(
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
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: skir.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
      ],
      configuration: [
        skir.ConfigurationRecipe(
          origin: ruleOrigin,
          relativePath: skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: fieldName)],
          ),
          representationCondition: skir.RepresentationKind.integer,
          rules: [
            skir.OwnedRule(
              id: ruleId,
              descriptor: skir.RuleDescriptor(
                predicate: skir.ExpressionNode.createCall(
                  operation: skir.OperationId(value: "typewriter.rule.minimum"),
                  arguments: [
                    skir.ExpressionNode.createRead(
                      binding: configured,
                      path: skir.ValuePath(segments: const []),
                    ),
                    skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapInteger(minimum.toString()),
                    ),
                    skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapBoolean(true),
                    ),
                  ],
                ),
              ),
              diagnostic: skir.DiagnosticTemplate(
                code: "minimum",
                message: "Must be at least $minimum",
                severity: skir.DiagnosticSeverity.error,
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
  final resource = skir.ResourceId(value: "repeating:one");
  final record = skir.AuthoringRecord(
    configuration: skir.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    ),
    fields: [
      skir.FieldValue(
        name: fieldName,
        value: initial ?? skir.DataValue.wrapInteger("2"),
      ),
    ],
  );
  return (
    resource: resource,
    catalog: checked,
    draft: AuthoredDraft(
      generation: catalogGeneration,
      resources: [
        skir.AuthoringResource(
          id: resource,
          definition: skir.ResourceDefinitionId(value: "test.repeating"),
          content: record,
        ),
      ],
      links: const [],
      catalog: checked,
    ),
  );
}

({skir.ResourceId resource, AuthoredDraft draft, CheckedEditorCatalog catalog})
_fixture({
  String snapshot = "realm:1",
  String title = "Original",
  bool requireTitle = false,
  String fieldName = "title",
  skir.DataValue? initial,
  skir.NamedTypeUse? namedText,
}) {
  final generation = skir.CatalogGeneration(value: "catalog:1");
  final fieldType = namedText == null
      ? skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)
      : skir.TypeTemplate.createNamed(
          definition: namedText.definition,
          arguments: const [],
        );
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.wrapQualified(
      skir.QualifiedTypeId(namespace: "test", name: "Message"),
    ),
    revision: 1,
  );
  final presentationId = skir.PresentationId(
    namespace: "test",
    name: "message.editor",
  );
  final ruleOrigin = skir.RuleOrigin(owner: definition, ordinal: 0);
  final titleRule = skir.RuleId(origin: ruleOrigin, localIndex: 0);
  final target = skir.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  final layout = skir.PresentationNode(
    nodeId: "message.title",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.createTextInput(
      control: skir.BoundControl(
        binding: skir.BindingRef(
          bindingId: configuredValueBindingId,
          path: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: fieldName)],
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
  final headerLayout = skir.PresentationNode(
    nodeId: "message.header",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.createText(
      value: skir.ExpressionNode.createRead(
        binding: configuredValueBindingId,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: fieldName)],
        ),
      ),
      color: null,
      sizing: null,
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
      paragraph: skir.TextParagraph.defaultInstance,
    ),
    header: null,
  );
  final graphLayout = skir.PresentationNode(
    nodeId: "message.graph",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.createAdaptiveLeading(
      leading: skir.PresentationNode(
        nodeId: "message.graph.icon.color",
        properties: skir.PresentationProperties.defaultInstance,
        element: skir.PresentationElement.createContainer(
          foregroundColor: null,
          transitionMilliseconds: 0,
          child: skir.PresentationNode(
            nodeId: "message.graph.icon.padding",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.createPadding(
              child: skir.PresentationNode(
                nodeId: "message.graph.icon",
                properties: skir.PresentationProperties.defaultInstance,
                element: skir.PresentationElement.createIcon(
                  name: skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapStringValue(
                      '<svg xmlns="http://www.w3.org/2000/svg" '
                      'viewBox="0 0 24 24">'
                      ' <path d="M4 4h16v16H4z"/></svg>',
                    ),
                  ),
                  semanticLabel: skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapStringValue("Tag"),
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
          backgroundColor: skir.PresentationColor.wrapValue(
            skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapInteger("4288585374"),
            ),
          ),
          radius: skir.PresentationRadius.none,
        ),
        header: null,
      ),
      center: headerLayout,
      suffix: null,
      padding: skir.PresentationInsets.wrapAll(8),
      compactPadding: skir.PresentationInsets.wrapAll(4),
      gap: 12,
      minimumCenterWidth: 80,
    ),
    header: null,
  );
  final generatedGraphLayout = skir.PresentationNode(
    nodeId: "message.graph.root",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        children: [skir.AxisChild.wrapFixed(graphLayout)],
        layout: skir.AxisChildrenLayout(
          spacing: 0,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
      ),
    ),
    header: null,
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        if (namedText != null)
          skir.PublishedType(
            display: null,
            definition: skir.TypeDefinition(
              id: namedText.definition,
              parameters: const [],
              representation: skir.RepresentationTemplate.createScalar(
                kind: skir.ScalarKind.text,
              ),
              parents: const [],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: const [],
          ),
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: definition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: skir.FieldOwner(
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
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: fieldName,
              owner: skir.FieldOwner(definition: definition, name: fieldName),
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
        skir.PresentationDescriptor(
          id: presentationId,
          owner: skir.DeclarationOwner.defaultInstance,
          target: target,
          roles: [
            skir.PresentationRole.editor,
            skir.PresentationRole.inspector,
            skir.PresentationRole.graphNode,
          ],
          priority: 0,
        ),
      ],
      presentationMaterials: [
        skir.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: skir.PresentationRole.editor,
          layout: layout,
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: skir.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
        skir.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: skir.PresentationRole.inspector,
          layout: skir.PresentationNode(
            nodeId: "message.inspector",
            properties: skir.PresentationProperties.defaultInstance,
            header: null,
            element: skir.PresentationElement.wrapChildren(
              skir.ChildrenElement.createColumn(
                children: [
                  skir.AxisChild.wrapFixed(headerLayout),
                  skir.AxisChild.wrapFixed(layout),
                ],
                layout: skir.AxisChildrenLayout.defaultInstance,
              ),
            ),
          ),
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: skir.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
        skir.PresentationMaterial(
          provider: presentationId,
          target: target,
          role: skir.PresentationRole.graphNode,
          layout: generatedGraphLayout,
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: skir.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
      ],
      configuration: requireTitle
          ? [
              skir.ConfigurationRecipe(
                origin: ruleOrigin,
                relativePath: skir.RelativeFieldPattern(
                  segments: [
                    skir.FieldPatternSegment.createField(name: fieldName),
                  ],
                ),
                representationCondition: skir.RepresentationKind.text,
                rules: [
                  skir.OwnedRule(
                    id: titleRule,
                    descriptor: skir.RuleDescriptor(
                      predicate: skir.ExpressionNode.createCall(
                        operation: skir.OperationId(
                          value: "typewriter.rule.nonBlank",
                        ),
                        arguments: [
                          skir.ExpressionNode.createRead(
                            binding: configuredValueBindingId,
                            path: skir.ValuePath(segments: const []),
                          ),
                        ],
                      ),
                    ),
                    diagnostic: skir.DiagnosticTemplate(
                      code: "non_blank",
                      message: "Title must not be blank",
                      severity: skir.DiagnosticSeverity.error,
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
  final resource = skir.ResourceId(value: "message:one");
  final record = skir.AuthoringRecord(
    configuration: skir.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    ),
    fields: [
      skir.FieldValue(
        name: fieldName,
        value: initial ?? skir.DataValue.wrapStringValue(title),
      ),
    ],
  );
  final draft = AuthoredDraft(
    generation: generation,
    resources: [
      skir.AuthoringResource(
        id: resource,
        definition: skir.ResourceDefinitionId(value: "test.message"),
        content: record,
      ),
    ],
    links: const [],
    catalog: checked,
  );
  return (resource: resource, draft: draft, catalog: checked);
}

final _chapterTextType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "ChapterPath"),
    revision: 1,
  ),
  arguments: const [],
);
