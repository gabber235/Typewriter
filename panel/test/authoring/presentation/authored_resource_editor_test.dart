import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "conflict preserves the focused field and exposes group recovery",
    (tester) async {
      final fixture = AuthoredDraft.titled(
        fieldName: "name",
        initial: skir.DataValue.wrapStringValue("Saved"),
      );
      final panel = await tester.pumpPanel(fixture.servedHeld);
      final workspace = await panel.openEditing();
      workspace.form(fixture.draft.resources.keys.first);
      final seeded = panel.world.requireRealm;
      await panel.showAbove(
        Scaffold(
          body: SingleChildScrollView(
            child: AuthoredResourceInspection(
              commitPolicy: EditorCommitPolicy.applyResource,
              resource: fixture.resource,
              workspace: workspace,
              commands: seeded.commands,
            ),
          ),
        ),
      );
      final input = panel.fieldAt(0);
      await input.type("Local");
      final remote = AuthoringEdit.fromDocument(seeded.document)
        ..set(
          authoredFieldLocation(fixture.resource, ["name"]),
          skir.DataValue.wrapStringValue("Remote"),
        );
      seeded.serve(remote.toDocument());
      workspace.acceptConfirmed(remote.toDocument());
      await tester.pump();
      expect(input.isReadOnly, isTrue);
      expect(input.isFocused, isTrue);
      expect(find.text("Review changes"), findsOneWidget);
      Focus.of(tester.element(find.text("Review changes"))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(AuthoringConflictComparison), findsOneWidget);
      expect(find.text("Local"), findsWidgets);
      expect(find.text("Remote"), findsWidgets);
      // The review opens on its main action.
      expect(panel.hasFocusOn("Keep mine"), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(input.isReadOnly, isFalse);
      expect(input.isFocused, isTrue);
      expect(input.value, "Local");
      expect(seeded.saves, isEmpty);
    },
  );

  testWidgets("a review that offers no Keep mine opens on Close", (
    tester,
  ) async {
    final fixture = AuthoredDraft.titled(
      fieldName: "name",
      initial: skir.DataValue.wrapStringValue("Saved"),
    );
    final panel = await tester.pumpPanel(fixture.servedHeld);
    final workspace = await panel.inspectDraft(
      fixture,
      policy: EditorCommitPolicy.applyResource,
    );
    final seeded = panel.world.requireRealm;
    await panel.fieldAt(0).type("Local");
    // The resource is gone, so keeping the local edit is not offered.
    final removed = seeded.document.copyWith(entries: {});
    seeded.serve(removed);
    workspace.acceptConfirmed(removed);
    await panel.settle();
    await panel.activateWithKeyboard(find.text("Review changes"));
    await panel.settle();
    expect(find.byType(AuthoringConflictComparison), findsOneWidget);
    expect(panel.hasFocusOn("Close"), isTrue);
  });

  testWidgets("comparison rejects a stale action without losing its proposal", (
    tester,
  ) async {
    final fixture = AuthoredDraft.titled(
      fieldName: "name",
      initial: skir.DataValue.wrapStringValue("Saved"),
    );
    final panel = await tester.pumpPanel(fixture.servedHeld);
    final workspace = await panel.openEditing();
    final binding = workspace.form(fixture.draft.resources.keys.first);
    final seeded = panel.world.requireRealm;
    binding.setText(
      "Rename",
      authoredFieldLocation(fixture.resource, ["name"]),
      "Local",
    );
    final remote = AuthoringEdit.fromDocument(seeded.document)
      ..set(
        authoredFieldLocation(fixture.resource, ["name"]),
        skir.DataValue.wrapStringValue("Remote"),
      );
    seeded.serve(remote.toDocument());
    final review = await workspace.refreshedConflictReview(
      binding.editingGroup,
    );
    await panel.showAbove(
      Scaffold(
        body: SizedBox(
          width: 420,
          child: AuthoringConflictComparison(
            review: review,
            onKeepMine: () => workspace.resolveConflict(
              review,
              AuthoringConflictChoice.keepMine,
            ),
            onUseSaved: () => workspace.resolveConflict(
              review,
              AuthoringConflictChoice.useSaved,
            ),
          ),
        ),
      ),
    );
    final newer = AuthoringEdit.fromDocument(remote.toDocument())
      ..set(
        authoredFieldLocation(fixture.resource, ["name"]),
        skir.DataValue.wrapStringValue("Changed again"),
      );
    workspace.acceptConfirmed(newer.toDocument());
    await tester.tap(find.text("Keep mine"));
    await tester.pump();
    expect(
      find.text("These changes changed again. Review the current values"),
      findsOneWidget,
    );
    expect(
      workspace.document.resource(fixture.resource)!.authoredField("name"),
      skir.DataValue.wrapStringValue("Local"),
    );
    expect(tester.takeException(), isNull);
  });

  for (final kind in ["named", "expected named Unfilled", "ordinary"]) {
    final named = kind != "ordinary";
    final initial = kind == "expected named Unfilled"
        ? skir.DataValue.unfilled
        : named
        ? skir.DataValue.createNamed(
            actualType: _chapterTextType,
            payload: skir.DataValue.wrapStringValue("old.chapter"),
          )
        : skir.DataValue.wrapStringValue("old.chapter");
    final chapterType = named ? _chapterTextType : null;

    testWidgets("typing $kind text saves it, refused if the chapter changed "
        "meanwhile", (tester) async {
      final fixture = AuthoredDraft.titled(
        fieldName: "chapter",
        initial: initial,
        namedText: chapterType,
      );
      final panel = await tester.pumpPanel(fixture.servedHeld);
      final binding = await panel.editDraft(fixture);
      final workspace = binding.workspace;
      final seeded = panel.world.requireRealm;
      final chapter = authoredFieldLocation(fixture.resource, ["chapter"]);
      final saved = seeded.document;

      await FieldDriver.at(tester, 0).type("new.chapter");
      await tester.pump();
      expect(
        workspace.document.resource(fixture.resource)!.authoredField("chapter"),
        textValue("new.chapter", type: chapterType),
      );
      final saving = binding.save();
      await tester.pump();
      final sent = seeded.saves.single;
      expect(
        sent.edit,
        refusedAfter(
          (remote) => remote.set(
            chapter,
            textValue("remote.chapter", type: chapterType),
          ),
          saved: saved,
        ),
      );
      sent.confirm();
      await saving;

      expect(
        seeded.document.resource(fixture.resource)!.authoredField("chapter"),
        textValue("new.chapter", type: chapterType),
      );
    });

    testWidgets("clearing typed $kind text keeps its text type", (
      tester,
    ) async {
      final fixture = AuthoredDraft.titled(
        fieldName: "chapter",
        initial: initial,
        namedText: chapterType,
      );
      final panel = await tester.pumpPanel(fixture.servedHeld);
      final binding = await panel.editDraft(fixture);
      final workspace = binding.workspace;
      await FieldDriver.at(tester, 0).type("new.chapter");
      await tester.pump();

      await FieldDriver.at(tester, 0).type("");
      await tester.pump();

      expect(
        workspace.document.resource(fixture.resource)!.authoredField("chapter"),
        textValue("", type: chapterType),
      );
    });
  }

  for (final field in ["name", "chapter", "priority"]) {
    testWidgets("filling an Unfilled $field autosaves it, refused once "
        "someone else filled it", (tester) async {
      final fixture = field == "priority"
          ? AuthoredDraft.numeric(
              generation: "catalog:1",
              snapshot: "realm:1",
              minimum: 0,
              fieldName: field,
              initial: skir.DataValue.unfilled,
            )
          : AuthoredDraft.titled(
              fieldName: field,
              initial: skir.DataValue.unfilled,
            );
      final panel = await tester.pumpPanel(fixture.servedHeld);
      await panel.inspectDraft(fixture);
      final seeded = panel.world.requireRealm;
      await FieldDriver.at(tester, 0).type(field == "priority" ? "3" : "new");
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      final location = authoredFieldLocation(fixture.resource, [field]);
      final typed = field == "priority"
          ? skir.DataValue.wrapInteger("3")
          : skir.DataValue.wrapStringValue("new");
      final sent = seeded.saves.single;
      expect(
        sent.edit,
        refusedAfter(
          (remote) => remote.set(
            location,
            field == "priority"
                ? skir.DataValue.wrapInteger("7")
                : skir.DataValue.wrapStringValue("remote"),
          ),
          saved: fixture.draft.toDocument(),
        ),
      );
      sent.confirm();
      await tester.pump();
      expect(
        seeded.document.resource(fixture.resource)!.authoredField(field),
        typed,
      );
      expect(find.textContaining("changed"), findsNothing);
      await tester.pumpAndSettle();
    });
  }

  testWidgets("two inspectors share values and manual discard", (tester) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    final workspace = await panel.openEditing();
    workspace.form(fixture.draft.resources.keys.first);
    final seeded = panel.world.requireRealm;
    final commands = seeded.commands;
    await panel.showAbove(
      Scaffold(
        body: Row(
          children: [
            for (var index = 0; index < 2; index++)
              Expanded(
                child: AuthoredResourceInspection(
                  resource: fixture.resource,
                  workspace: workspace,
                  commands: commands,
                  commitPolicy: EditorCommitPolicy.applyResource,
                ),
              ),
          ],
        ),
      ),
    );
    await FieldDriver.at(tester, 0).type("Shared");
    await tester.pumpAndSettle();
    expect(
      [
        for (final index in [0, 1]) FieldDriver.at(tester, index).value,
      ],
      ["Shared", "Shared"],
    );
    expect(workspace.state.groups, hasLength(1));
    expect(find.text("Apply"), findsNWidgets(2));
    await tester.tap(find.text("Discard").last);
    await tester.pumpAndSettle();
    expect(
      [
        for (final index in [0, 1]) FieldDriver.at(tester, index).value,
      ],
      ["Original", "Original"],
    );
    expect(seeded.saves, isEmpty);
  });

  testWidgets("closing an inspector retains work for a later editor", (
    tester,
  ) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    final binding = await panel.editDraft(fixture);
    final workspace = binding.workspace;
    await FieldDriver.at(tester, 0).type("Retained");
    await panel.closeAbove();
    binding.detach();
    final next = workspace.form(fixture.resource);
    await panel.showAbove(
      Scaffold(
        body: AuthoredResourceEditor(
          resource: fixture.resource,
          document: next.document,
          edit: next,
          role: skir.PresentationRole.inspector,
          budget: skir.EvaluationBudget(
            maxSteps: 10000,
            maxCollectionItems: 10000,
          ),
        ),
      ),
    );
    expect(find.text("Retained"), findsWidgets);
    expect(next.dirty, isTrue);
  });

  testWidgets("inline group controls compare retained work", (tester) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    final workspace = await panel.openEditing();
    workspace.form(fixture.draft.resources.keys.first)
      ..setText(
        "Rename message",
        authoredFieldLocation(fixture.resource, ["title"]),
        "Local",
      )
      ..detach();
    await panel.showAbove(
      EditingGroupPanel(
        workspace: workspace.workspace,
        id: workspace.state.groups.values.single.id,
        review: () => RealmEditingReview(
          workspace: workspace,
          id: workspace.state.groups.values.single.id,
        ),
      ),
    );
    expect(find.text("Rename message"), findsOneWidget);
    await tester.tap(find.text("View changes"));
    await tester.pumpAndSettle();
    expect(find.text("Working"), findsOneWidget);
    expect(find.text("Saved"), findsOneWidget);
    expect(find.text("Before changes"), findsOneWidget);
    final compared = [
      for (final index in [0, 1, 2]) FieldDriver.at(tester, index),
    ];
    expect(visibleTextFields(), hasLength(3));
    expect([
      for (final field in compared) field.isReadOnly,
    ], everyElement(isTrue));
    await tester.tap(find.text("Close"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Discard"));
    await tester.pumpAndSettle();
    expect(workspace.state.groups, isEmpty);
  });

  testWidgets("empty page graph receives the bounded editor workspace", (
    tester,
  ) async {
    final fixture = AuthoredDraft.pageGraph();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    await panel.inspectDraft(fixture, role: skir.PresentationRole.workspace);
    expect(tester.takeException(), isNull);
    expect(find.byType(Graph), findsOneWidget);
    final size = tester.getSize(find.byType(Graph));
    expect(size.width.isFinite && size.height.isFinite, isTrue);
    expect(size.width > 0 && size.height > 0, isTrue);
  });

  group("a page holding a child whose title is blank", () {
    const message = "Title must not be blank";

    testWidgets("keeps the child's finding off the page canvas", (
      tester,
    ) async {
      final page = AuthoredDraft.pageGraph();
      final child = AuthoredDraft.titled(title: "", requireTitle: true);
      final document = page.holding(child);
      expect(
        ResourceIssues.evaluate(document: document)
            .currentFor(child.resource)
            .single
            .diagnostic
            .message,
        message,
      );

      final panel = await tester.pumpPanel([
        ...adaServing(document),
        heldSaves,
      ]);
      await panel.showDocumentEditor(page.resource, document);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel("Tag"), findsOneWidget);
      expect(find.text(message), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("shows the finding on the child's item behind a focusable "
        "marker", (tester) async {
      final page = AuthoredDraft.pageGraph();
      final child = AuthoredDraft.titled(title: "", requireTitle: true);
      final document = page.holding(child);

      final panel = await tester.pumpPanel([
        ...adaServing(document),
        heldSaves,
      ]);
      await panel.showAbove(
        Scaffold(
          body: AuthoredResourceEditor(
            resource: child.resource,
            document: document,
            role: skir.PresentationRole.item,
            budget: skir.EvaluationBudget(
              maxSteps: 1000,
              maxCollectionItems: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final marker = find.bySemanticsLabel("Presentation error");
      expect(marker, findsOneWidget);
      Focus.of(
        tester.element(
          find.descendant(of: marker, matching: find.byType(Icon)).first,
        ),
      ).requestFocus();
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    "embedded page resources admit missing caller inputs with declared types",
    (tester) async {
      final page = AuthoredDraft.pageGraph();
      final child = AuthoredDraft.titled();
      final childType = child.catalog.snapshot.types.first.definition.id;
      final caller = skir.ExpressionBindingId(
        value: "context:test.page.caller",
      );
      final callerType = skir.TypeUse.wrapNamed(skir.resourceIdType);
      final fallback = skir.ExpressionNode.createOrElse(
        value: skir.ExpressionNode.createField(
          source: portableCall(
            "resource.value_of",
            [
              skir.ExpressionNode.createInput(
                binding: caller,
                path: editorRootPath,
              ),
            ],
            typeArguments: [
              skir.TypeTemplate.createNamed(
                definition: childType,
                arguments: const [],
              ),
            ],
          ),
          path: editorRootPath.field("title"),
        ),
        fallback: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("No caller supplied"),
        ),
      );
      final embeddedMaterials = child.catalog.snapshot.presentationMaterials
          .map((material) {
            if (material.role != skir.PresentationRole.item) {
              return material;
            }
            final text = skir.TextContent.defaultInstance.toMutable()
              ..value = fallback;
            final dependencies = material.dependencies.toMutable()
              ..contextInputs = [
                skir.PresentationContextInput(
                  source: skir.PresentationContextSource.caller,
                  binding: declareBinding(caller, callerType.portableTemplate),
                ),
              ];
            return (material.toMutable()
                  ..layout = skir.PresentationNode(
                    nodeId: "embedded.caller.fallback",
                    properties: skir.PresentationProperties.defaultInstance,
                    header: null,
                    element: skir.PresentationElement.wrapText(text.toFrozen()),
                  )
                  ..dependencies = dependencies.toFrozen())
                .toFrozen();
          })
          .toList();
      final document = page.holding(
        child,
        childMaterials: embeddedMaterials,
        types: [
          publishedType(
            skir.resourceIdType.definition,
            representation: skir.RepresentationTemplate.createScalar(
              kind: skir.ScalarKind.text,
            ),
          ),
        ],
      );
      final unbound = PortableExpressionEvaluator.located(
        const {},
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
        queries: PortableExpressionQueries(
          catalog: document.catalog,
          authored: document,
        ),
      ).evaluate(fallback);
      expect(
        unbound,
        isA<PortableExpressionFailed>().having(
          (failure) => failure.failure,
          "failure",
          skir.PortableFailures.unknownExpressionBinding,
        ),
      );
      final panel = await tester.pumpPanel([
        ...adaServing(document),
        heldSaves,
      ]);
      await panel.showDocumentEditor(page.resource, document);
      await tester.pumpAndSettle();
      expect(find.byType(Graph), findsOneWidget);
      expect(find.text("No caller supplied"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("numeric clearing preserves Unfilled and repair", (tester) async {
    final fixture = AuthoredDraft.numeric(
      generation: "catalog:1",
      snapshot: "realm:1",
      minimum: 1,
    );
    final panel = await tester.pumpPanel(fixture.servedHeld);
    final binding = await panel.editDraft(fixture);
    final workspace = binding.workspace;
    await FieldDriver.at(tester, 0).type("");
    await tester.pump();
    expect(
      workspace.document
          .resource(fixture.resource)!
          .authoredField("repetitions"),
      skir.DataValue.unfilled,
    );
    await FieldDriver.at(tester, 0).type("7");
    await tester.pump();
    expect(
      workspace.document
          .resource(fixture.resource)!
          .authoredField("repetitions")!
          .authoredInteger,
      BigInt.from(7),
    );
    await tester.pumpAndSettle();
  });

  testWidgets("catalog changes retain the proposal and block editing", (
    tester,
  ) async {
    final first = AuthoredDraft.numeric(
      generation: "catalog:1",
      snapshot: "realm:1",
      minimum: 1,
    );
    final panel = await tester.pumpPanel(first.servedHeld);
    final workspace = await panel.openEditing();
    final binding = workspace.form(first.draft.resources.keys.first);
    final seeded = panel.world.requireRealm;
    final commands = seeded.commands;
    await panel.showAbove(
      Scaffold(
        body: AuthoredResourceInspection(
          resource: first.resource,
          workspace: workspace,
          commands: commands,
          commitPolicy: EditorCommitPolicy.applyResource,
        ),
      ),
    );
    await FieldDriver.at(tester, 0).type("3");
    await tester.pump();
    final second = AuthoredDraft.numeric(
      generation: "catalog:2",
      snapshot: "realm:2",
      minimum: 10,
    );
    workspace.acceptConfirmed(second.draft.toDocument());
    await tester.pump();
    expect(binding.phase, isA<EditGroupContractChanged>());
    expect(workspace.document.generation, first.draft.generation);
    await tester.tap(find.text("Discard"));
    await tester.pump();
    expect(workspace.document.generation, second.draft.generation);
    await tester.pumpAndSettle();
  });
  group("a one cell graph card", () {
    testWidgets("with a blank title shows its error only while its marker "
        "has focus", (tester) async {
      await AuthoredDraft.titled(
        title: "",
        requireTitle: true,
      ).showItemCard(tester, width: 48);
      final marker = find.bySemanticsLabel("Presentation error");
      expect(marker, findsOneWidget);
      expect(find.text("Title must not be blank"), findsNothing);

      final focus = Focus.of(
        tester.element(
          find.descendant(of: marker, matching: find.byType(Icon)).first,
        ),
      )..requestFocus();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("Title must not be blank"), findsOneWidget);

      focus.unfocus();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("Title must not be blank"), findsNothing);
    });

    testWidgets("with a valid title shows no error marker", (tester) async {
      await AuthoredDraft.titled(title: "Quest")
          .showItemCard(tester, width: 48);

      expect(find.bySemanticsLabel("Presentation error"), findsNothing);
    });

    testWidgets("with room for it shows its title", (tester) async {
      await AuthoredDraft.titled(title: "Quest")
          .showItemCard(tester, width: 180);

      expect(find.text("Quest"), findsOneWidget);
    });
  });

  testWidgets("editor roles leave unmatched resource findings with the inbox", (
    tester,
  ) async {
    final fixture = AuthoredDraft.titled(
      title: "",
      requireTitle: true,
      inspectorLayout:
          (skir.PresentationNode.mutable()
                ..nodeId = "canvas"
                ..element = skir.PresentationElement.wrapText(
                  (skir.TextContent.mutable()
                        ..value = skir.ExpressionNode.wrapLiteral(
                          skir.DataValue.wrapStringValue("Canvas"),
                        ))
                      .toFrozen(),
                ))
              .toFrozen(),
    );
    final panel = await tester.pumpPanel(fixture.servedHeld);
    await panel.showAbove(
      Scaffold(
        body: AuthoredResourceEditor(
          resource: fixture.resource,
          document: fixture.draft.toDocument(),
          role: skir.PresentationRole.workspace,
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Title must not be blank"), findsNothing);
    expect(find.bySemanticsLabel("Presentation error"), findsNothing);
  });

  for (final showTitleEditor in [true, false]) {
    testWidgets(
      "only Title shows its error with editor present: $showTitleEditor",
      (tester) async {
        final fixture = AuthoredDraft.titled(
          title: "",
          requireTitle: true,
          inspectorLayout: bookSectionsLayout(showTitleEditor: showTitleEditor),
        );
        final panel = await tester.pumpPanel(fixture.servedHeld);
        await panel.showAbove(
          Scaffold(
            body: SingleChildScrollView(
              child: AuthoredResourceEditor(
                resource: fixture.resource,
                document: fixture.draft.toDocument(),
                role: skir.PresentationRole.inspector,
                budget: skir.EvaluationBudget(
                  maxSteps: 1000,
                  maxCollectionItems: 100,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The panel around the editor lists the Realm's issues in its inbox;
        // only what the editor itself shows counts here.
        Finder inEditor(Finder finder) => find.descendant(
          of: find.byType(AuthoredResourceEditor),
          matching: finder,
        );
        expect(inEditor(find.text("Title must not be blank")), findsOneWidget);
        expect(inEditor(find.text("1 issue")), findsNothing);
        expect(
          inEditor(find.text("Saved review differs from this draft")),
          findsNothing,
        );
        expect(visibleTextFields(), hasLength(showTitleEditor ? 1 : 0));
        expect(
          inEditor(find.bySemanticsLabel("Presentation error")),
          findsNothing,
        );
        // The error reads under the Title section, before the next one.
        final error = tester.getTopLeft(
          inEditor(find.text("Title must not be blank")),
        );
        expect(
          error.dy,
          greaterThan(tester.getTopLeft(inEditor(find.text("Title"))).dy),
        );
        expect(
          error.dy,
          lessThan(tester.getTopLeft(inEditor(find.text("Icon"))).dy),
        );
        for (final title in [
          "Icon",
          "Color",
          "Direct Tags",
          "Effective Tags",
        ]) {
          expect(inEditor(find.text(title)), findsOneWidget);
        }
      },
    );
  }
}

final _chapterTextType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "ChapterPath"),
    revision: 1,
  ),
  arguments: const [],
);
