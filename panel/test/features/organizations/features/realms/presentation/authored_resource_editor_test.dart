import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  for (final kind in ["named", "expected named Unfilled", "ordinary"]) {
    testWidgets("direct $kind text preserves identity through edit and clear", (
      tester,
    ) async {
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
      final authoring = _editing(fixture.draft);
      await tester.pumpTestApp(
        child: Scaffold(body: _editor(fixture.resource, authoring.binding)),
      );
      await tester.enterText(find.byType(TextFormField), "new.chapter");
      await tester.pump();
      final expected = named
          ? skir.DataValue.createNamed(
              actualType: _chapterTextType,
              payload: skir.DataValue.wrapStringValue("new.chapter"),
            )
          : skir.DataValue.wrapStringValue("new.chapter");
      expect(
        authoring.workspace.document
            .resource(fixture.resource)!
            .authoredField("chapter"),
        expected,
      );
      final saving = authoring.binding.save();
      await tester.pump();
      final submitted = authoring.transport.requests.single.edit;
      final set = submitted.intents.single as skir.EditIntent_setValueWrapper;
      expect(
        set.value.at,
        authoredFieldLocation(fixture.resource, ["chapter"]),
      );
      expect(set.value.value, expected);
      expect(
        submitted.expectations
            .whereType<skir.EditExpectation_valueWrapper>()
            .single
            .value
            .expected,
        initial,
      );
      final branch = AuthoringEdit.fromDocument(
        authoring.transport.observation.requireValue,
      )..set(set.value.at, expected);
      authoring.transport.confirm(0, branch.toDocument());
      await saving;
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), "");
      await tester.pump();
      expect(
        authoring.workspace.document
            .resource(fixture.resource)!
            .authoredField("chapter"),
        named
            ? skir.DataValue.createNamed(
                actualType: _chapterTextType,
                payload: skir.DataValue.wrapStringValue(""),
              )
            : skir.DataValue.wrapStringValue(""),
      );
    });
  }

  for (final field in ["name", "chapter", "priority"]) {
    testWidgets("inspector saves Unfilled $field with exact expectation", (
      tester,
    ) async {
      final fixture = field == "priority"
          ? _numericFixture(
              generation: "catalog:1",
              snapshot: "realm:1",
              minimum: 0,
              fieldName: field,
              initial: skir.DataValue.unfilled,
            )
          : _fixture(fieldName: field, initial: skir.DataValue.unfilled);
      final authoring = _editing(
        fixture.draft,
        policy: EditorCommitPolicy.autosaveChanges,
      );
      await tester.pumpTestApp(
        child: Scaffold(
          body: AuthoredResourceInspection(
            resource: fixture.resource,
            workspace: authoring.workspace,
            commands: fixtureAuthoringCommands(authoring.transport),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField),
        field == "priority" ? "3" : "new",
      );
      await tester.pump(AuthoringWorkspace.debounce);
      await tester.pump();
      final submitted = authoring.transport.requests.single.edit;
      final set = submitted.intents.single as skir.EditIntent_setValueWrapper;
      expect(set.value.at, authoredFieldLocation(fixture.resource, [field]));
      expect(
        set.value.value,
        field == "priority"
            ? skir.DataValue.wrapInteger("3")
            : skir.DataValue.wrapStringValue("new"),
      );
      expect(
        submitted.expectations
            .whereType<skir.EditExpectation_valueWrapper>()
            .single
            .value
            .expected,
        skir.DataValue.unfilled,
      );
      expect(find.textContaining("changed"), findsNothing);
      await tester.pumpAndSettle();
    });
  }

  testWidgets("two inspectors share values and manual discard", (tester) async {
    final fixture = _fixture();
    final authoring = _editing(fixture.draft);
    final commands = fixtureAuthoringCommands(authoring.transport);
    await tester.pumpTestApp(
      child: Scaffold(
        body: Row(
          children: [
            for (var index = 0; index < 2; index++)
              Expanded(
                child: AuthoredResourceInspection(
                  resource: fixture.resource,
                  workspace: authoring.workspace,
                  commands: commands,
                  commitPolicy: EditorCommitPolicy.applyResource,
                ),
              ),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, "Shared");
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((field) => field.controller!.text),
      ["Shared", "Shared"],
    );
    expect(authoring.workspace.state.groups, hasLength(1));
    expect(find.text("Apply"), findsNWidgets(2));
    await tester.tap(find.text("Cancel").last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((field) => field.controller!.text),
      ["Original", "Original"],
    );
    expect(authoring.transport.requests, isEmpty);
  });

  testWidgets("closing an inspector retains work for a later editor", (
    tester,
  ) async {
    final fixture = _fixture();
    final authoring = _editing(fixture.draft);
    await tester.pumpTestApp(
      child: Scaffold(body: _editor(fixture.resource, authoring.binding)),
    );
    await tester.enterText(find.byType(TextFormField), "Retained");
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    authoring.binding.detach();
    final next = authoring.workspace.attach(
      fixture.resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(next.detach);
    await tester.pumpTestApp(
      child: Scaffold(body: _editor(fixture.resource, next)),
    );
    expect(find.text("Retained"), findsWidgets);
    expect(next.dirty, isTrue);
  });

  testWidgets("pending work remains accessible without an inspector", (
    tester,
  ) async {
    final fixture = _fixture();
    final authoring = _editing(fixture.draft);
    authoring.binding.edit(
      label: "Rename message",
      apply: (edit) => edit.set(
        authoredFieldLocation(fixture.resource, ["title"]),
        skir.DataValue.wrapStringValue("Local"),
      ),
    );
    authoring.binding.detach();
    await tester.pumpTestApp(
      child: AuthoringPendingWork(workspace: authoring.workspace),
    );
    await tester.tap(find.text("Pending changes (1)"));
    await tester.pumpAndSettle();
    expect(find.text("Rename message"), findsOneWidget);
    await tester.tap(find.text("View changes"));
    await tester.pumpAndSettle();
    expect(find.text("Working"), findsOneWidget);
    expect(find.text("Saved"), findsOneWidget);
    expect(find.text("Before changes"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.readOnly, isTrue);
    }
    await tester.tap(find.text("Close"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Discard"));
    await tester.pumpAndSettle();
    expect(authoring.workspace.state.groups, isEmpty);
  });

  testWidgets("empty page graph receives the bounded editor workspace", (
    tester,
  ) async {
    final fixture = _emptyPageGraphFixture();
    final authoring = _editing(
      fixture.draft,
      policy: EditorCommitPolicy.autosaveChanges,
    );
    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredResourceInspection(
          resource: fixture.resource,
          workspace: authoring.workspace,
          commands: fixtureAuthoringCommands(authoring.transport),
          role: skir.PresentationRole.editor,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Graph), findsOneWidget);
    final size = tester.getSize(find.byType(Graph));
    expect(size.width.isFinite && size.height.isFinite, isTrue);
    expect(size.width > 0 && size.height > 0, isTrue);
  });

  testWidgets("numeric clearing preserves Unfilled and repair", (tester) async {
    final fixture = _numericFixture(
      generation: "catalog:1",
      snapshot: "realm:1",
      minimum: 1,
    );
    final authoring = _editing(fixture.draft);
    await tester.pumpTestApp(
      child: Scaffold(body: _editor(fixture.resource, authoring.binding)),
    );
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pump();
    expect(
      authoring.workspace.document
          .resource(fixture.resource)!
          .authoredField("repetitions"),
      skir.DataValue.unfilled,
    );
    await tester.enterText(find.byType(TextFormField), "7");
    await tester.pump();
    expect(
      authoring.workspace.document
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
    final first = _numericFixture(
      generation: "catalog:1",
      snapshot: "realm:1",
      minimum: 1,
    );
    final authoring = _editing(first.draft);
    final commands = fixtureAuthoringCommands(authoring.transport);
    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredResourceInspection(
          resource: first.resource,
          workspace: authoring.workspace,
          commands: commands,
          commitPolicy: EditorCommitPolicy.applyResource,
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), "3");
    await tester.pump();
    final second = _numericFixture(
      generation: "catalog:2",
      snapshot: "realm:2",
      minimum: 10,
    );
    authoring.workspace.acceptConfirmed(second.draft.toDocument());
    await tester.pump();
    expect(authoring.binding.phase, isA<AuthoringGroupCatalogChanged>());
    expect(authoring.workspace.document.generation, first.draft.generation);
    await tester.tap(find.text("Discard"));
    await tester.pump();
    expect(authoring.workspace.document.generation, second.draft.generation);
    await tester.pumpAndSettle();
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
                  document: fixture.draft.toDocument(),
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
          document: fixture.draft.toDocument(),
          role: skir.PresentationRole.editor,
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Title must not be blank"), findsOneWidget);
    expect(find.bySemanticsLabel("Presentation error"), findsNothing);
  });
}

Widget _editor(skir.ResourceId resource, AuthoringBinding binding) =>
    AuthoredResourceEditor(
      resource: resource,
      document: binding.document,
      edit: binding,
      role: skir.PresentationRole.inspector,
      budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
    );

({
  AuthoringWorkspace workspace,
  AuthoringBinding binding,
  ScriptedAuthoringTransport transport,
})
_editing(
  AuthoringEdit initial, {
  EditorCommitPolicy policy = EditorCommitPolicy.applyResource,
}) {
  final transport = ScriptedAuthoringTransport(AsyncData(initial.toDocument()));
  final workspace = AuthoringWorkspace(
    transport: transport,
    initial: initial.toDocument(),
  );
  final binding = workspace.attach(
    initial.resources.keys.first,
    policy: policy,
  );
  addTearDown(binding.detach);
  addTearDown(workspace.dispose);
  addTearDown(transport.dispose);
  return (workspace: workspace, binding: binding, transport: transport);
}

({skir.ResourceId resource, AuthoringEdit draft, CheckedEditorCatalog catalog})
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
  final draft = AuthoringEdit(
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

({skir.ResourceId resource, AuthoringEdit draft, CheckedEditorCatalog catalog})
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
    draft: AuthoringEdit(
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

({skir.ResourceId resource, AuthoringEdit draft, CheckedEditorCatalog catalog})
_fixture({
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
  final draft = AuthoringEdit(
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
