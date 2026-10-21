import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/catalog_fixture.dart";

void main() {
  test(
    "canonical resource fields remain pinned across same generation documents",
    () {
      final catalog = _catalog();
      final first = _document(catalog, "First");
      final second = _document(catalog, "Second");
      final expression = fieldExpression(
        _query(skir.ExpressionQuery.wrapResourceValue),
        "name",
      );
      expect(
        _evaluate(catalog, first, expression).value.authoredString,
        "First",
      );
      expect(
        _evaluate(catalog, second, expression).value.authoredString,
        "Second",
      );
      expect(
        _evaluate(catalog, first, expression).value.authoredString,
        "First",
      );
    },
  );

  test("declaration color is read canonically without sibling projection", () {
    final catalog = _catalog();
    final configuration = _query(
      skir.ExpressionQuery.wrapResourceConfiguration,
    );
    final declaration = skir.ExpressionNode.wrapQuery(
      skir.ExpressionQuery.wrapCatalogDeclaration(configuration),
    );
    final color = fieldExpression(
      fieldExpression(declaration, "display"),
      "color",
    );
    final result = _evaluate(catalog, _document(catalog, "Page"), color);
    expect(result.value, colorValue(0xff336699));
    expect(
      result.reads.where((read) => read.location?.resource == _resource),
      isNotEmpty,
    );
  });

  test(
    "typed resource mismatch is missing and does not read another resource",
    () {
      final catalog = _catalog();
      final document = _document(
        catalog,
        "Different",
        configuration: skir.TypeSelection.createComplete(
          definition: _other,
          arguments: const [],
        ),
      );
      final result = catalog.evaluateExpression(
        _query(skir.ExpressionQuery.wrapResourceValue),
        bindings: _bindings,
        budget: _budget,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: document,
        ),
      );
      expect(result, isA<PortableExpressionUnavailable>());
      expect(
        result.reads
            .where((read) => read.location != null)
            .single
            .location
            ?.resource,
        _resource,
      );
    },
  );

  test("pending selections keep declaration metadata and known fields", () {
    final catalog = _catalog(generic: true);
    final document = _document(
      catalog,
      "Pending",
      configuration: skir.TypeSelection.createPending(
        definition: _page,
        arguments: const [skir.ArgumentSelection.unfilled],
      ),
    );
    final name = fieldExpression(
      _query(skir.ExpressionQuery.wrapResourceValue, generic: true),
      "name",
    );
    expect(_evaluate(catalog, document, name).value.authoredString, "Pending");
    final declaration = skir.ExpressionNode.wrapQuery(
      skir.ExpressionQuery.wrapCatalogDeclaration(
        _query(skir.ExpressionQuery.wrapResourceConfiguration, generic: true),
      ),
    );
    expect(
      _evaluate(
        catalog,
        document,
        fieldExpression(fieldExpression(declaration, "display"), "name"),
      ).value.authoredString,
      "Page",
    );
  });

  test(
    "absent resources remain missing while unsupported capabilities fail",
    () {
      final catalog = _catalog();
      final expression = _query(skir.ExpressionQuery.wrapResourceValue);
      final empty = AuthoringDocument(
        catalog: catalog,
        entries: const {},
        links: const [],
      );
      final result = catalog.evaluateExpression(
        expression,
        bindings: _bindings,
        budget: _budget,
        queries: PortableExpressionQueries(catalog: catalog, authored: empty),
      );
      expect(result, isA<PortableExpressionUnavailable>());
      expect(
        result.reads
            .where((read) => read.location != null)
            .single
            .location
            ?.resource,
        _resource,
      );
      final unsupported = catalog.evaluateExpression(
        expression,
        bindings: _bindings,
        budget: _budget,
      );
      expect(unsupported, isA<PortableExpressionFailed>());
      expect(
        (unsupported as PortableExpressionFailed).code,
        "unsupported_query",
      );
    },
  );

  test(
    "unknown fields fail checking and an undeclared display reads the defaults",
    () {
      final catalog = _catalog(display: false);
      final document = _document(catalog, "Page");
      final declaration = skir.ExpressionNode.wrapQuery(
        skir.ExpressionQuery.wrapCatalogDeclaration(
          _query(skir.ExpressionQuery.wrapResourceConfiguration),
        ),
      );
      final expression = skir.ExpressionNode.createOrElse(
        input: fieldExpression(
          fieldExpression(declaration, "display"),
          "color",
        ),
        fallback: literalExpression(colorValue(0xff123456)),
      );
      expect(
        _evaluate(catalog, document, expression).value,
        colorValue(0xff607d8b),
      );
      final invalid = catalog.evaluateExpression(
        fieldExpression(declaration, "unknown"),
        bindings: _bindings,
        budget: _budget,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: document,
        ),
      );
      expect(invalid, isA<PortableExpressionFailed>());
    },
  );

  test(
    "canonical projection shares expression step and collection budgets",
    () {
      final catalog = _catalog();
      final document = _document(catalog, "Page");
      final declaration = skir.ExpressionNode.wrapQuery(
        skir.ExpressionQuery.wrapCatalogDeclaration(
          _query(skir.ExpressionQuery.wrapResourceConfiguration),
        ),
      );
      final result = catalog.evaluateExpression(
        declaration,
        bindings: _bindings,
        budget: skir.EvaluationBudget(maxSteps: 8, maxCollectionItems: 1),
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: document,
        ),
      );
      expect(result, isA<PortableExpressionFailed>());
      final leaf = _evaluate(
        catalog,
        document,
        fieldExpression(fieldExpression(declaration, "display"), "color"),
      );
      expect(leaf.value, colorValue(0xff336699));
    },
  );

  test(
    "reserved canonical identities cannot be published as authored types",
    () {
      final definition = skir.TypeDefinition(
        id: skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: canonicalReadNamespace,
            name: "custom",
          ),
          revision: 1,
        ),
        parameters: const [],
        representation: skir.RepresentationTemplate.createRecord(
          fields: const [],
          abstract_: false,
        ),
        parents: const [],
      );
      expect(
        () => CheckedEditorCatalog(
          (skir.EditorCatalog.mutable()..types = [_published(definition)])
              .toFrozen(),
        ),
        throwsFormatException,
      );
    },
  );
  test("reference iteration keeps contracts for equal trees under different schemas", () {
    final base = _catalog();
    final pageRef = _definition("PageRef");
    final otherRef = _definition("OtherRef");
    final otherName = skir.FieldDeclaration(
      owner: skir.FieldOwner(definition: _other, name: "name"),
      type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      overrides: const [],
      hasConstructorDefault: false,
    );
    final catalog = CheckedEditorCatalog(
      (base.snapshot.toMutable()
            ..types = [
              for (final type in base.snapshot.types)
                if (type.definition.id != _other) type,
              _published(
                skir.TypeDefinition(
                  id: _other,
                  parameters: const [],
                  parents: const [],
                  representation: skir.RepresentationTemplate.createRecord(
                    fields: [otherName],
                    abstract_: false,
                  ),
                ),
              ),
              _referencePublished(pageRef, _page),
              _referencePublished(otherRef, _other),
            ])
          .toFrozen(),
    );
    final other = skir.ResourceId(value: "other");
    final original = _document(catalog, "First");
    final document = original.copyWith(
      entries: {
        ...original.entries,
        other: skir.AuthoringResource(
          id: other,
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.createComplete(
              definition: _other,
              arguments: const [],
            ),
            fields: [
              skir.FieldValue(
                name: "name",
                value: skir.DataValue.wrapStringValue("Second"),
              ),
            ],
          ),
        ),
      },
    );
    final left = skir.ExpressionBindingId(value: "left");
    final right = skir.ExpressionBindingId(value: "right");
    final body = fieldExpression(
      skir.ExpressionNode.wrapQuery(
        skir.ExpressionQuery.wrapResourceValue(
          skir.ResourceQuerySource.wrapReference(
            skir.ExpressionNode.createLocal(
              depth: 0,
              slot: 0,
              path: editorRootPath,
            ),
          ),
        ),
      ),
      "name",
    );
    skir.ExpressionNode mapped(skir.ExpressionBindingId source) =>
        skir.ExpressionNode.createMap(
          source: skir.ExpressionNode.createOrElse(
            input: skir.ExpressionNode.createInput(
              binding: source,
              path: editorRootPath,
            ),
            fallback: literalExpression(
              skir.DataValue.createListValue(items: const []),
            ),
          ),
          body: body,
        );
    skir.ExpressionNode join(skir.ExpressionNode source) =>
        skir.ExpressionNode.createTextJoin(
          source: source,
          separator: literalExpression(skir.DataValue.wrapStringValue("")),
        );
    final result = catalog.evaluateExpression(
      skir.ExpressionNode.createTextInterpolate(
        parts: [join(mapped(left)), join(mapped(right))],
      ),
      bindings: {
        left: _referenceBinding(pageRef, _resource),
        right: _referenceBinding(otherRef, other),
      },
      budget: _budget,
      queries: PortableExpressionQueries(catalog: catalog, authored: document),
    );
    expect(
      result,
      isA<PortableExpressionAvailable>(),
      reason: result is PortableExpressionFailed ? result.message : "$result",
    );
    expect(
      (result as PortableExpressionAvailable).value.authoredString,
      "FirstSecond",
    );
  });
  test(
    "unlocated reference item aliases retain their lexical target schema",
    () {
      final base = _catalog();
      final ref = _definition("PageRef");
      final catalog = CheckedEditorCatalog(
        (base.snapshot.toMutable()
              ..types = [
                ...base.snapshot.types,
                _referencePublished(ref, _page),
              ])
            .toFrozen(),
      );
      final source = skir.ExpressionBindingId(value: "source");
      final item = skir.ExpressionBindingId(value: "item");
      final alias = skir.ExpressionBindingId(value: "alias");
      final operations = PortableOperationResults();
      addTearDown(operations.dispose);
      final scope = PortablePresentationScope(
        bindings: {source: _referenceBinding(ref, _resource)},
        budget: _budget,
        operations: operations,
        catalog: catalog,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: _document(catalog, "Aliased page"),
        ),
      );
      final itemScope = scope.withBinding(
        skir.BindingRef(
          bindingId: source,
          path: skir.ValuePath(
            segments: [
              skir.PathSegment.createItem(id: skir.ItemId(value: "one")),
            ],
          ),
        ),
        item,
      )!;
      final aliasScope = itemScope.withBinding(
        skir.BindingRef(bindingId: item, path: editorRootPath),
        alias,
      )!;
      expect(aliasScope.bindings[alias]?.location, isNull);
      expect(
        aliasScope.bindings[alias]?.schema,
        CompletePortablePresentationBinding(
          skir.TypeUse.createNamed(definition: ref, arguments: const []),
        ),
      );
      final result = aliasScope.evaluate(
        fieldExpression(
          skir.ExpressionNode.wrapQuery(
            skir.ExpressionQuery.wrapResourceValue(
              skir.ResourceQuerySource.wrapReference(
                skir.ExpressionNode.createInput(
                  binding: alias,
                  path: editorRootPath,
                ),
              ),
            ),
          ),
          "name",
        ),
      );
      expect(result, isA<PortableExpressionAvailable>());
      expect(
        (result as PortableExpressionAvailable).value.authoredString,
        "Aliased page",
      );
    },
  );
  for (final directWrite in [false, true]) {
    for (final changedDependency in [false, true]) {
      test(
        "${directWrite ? 'write' : 'action'} observes the captured query dependency, changed=$changedDependency",
        () async {
          final catalog = _catalog();
          final source = _document(catalog, "Original");
          final dependency = skir.ResourceId(value: "dependency");
          final unrelated = skir.ResourceId(value: "unrelated");
          skir.AuthoringResource entry(skir.ResourceId id, String name) =>
              skir.AuthoringResource(
                id: id,
                content: skir.AuthoringRecord(
                  configuration: skir.TypeSelection.createComplete(
                    definition: _page,
                    arguments: const [],
                  ),
                  fields: [
                    skir.FieldValue(
                      name: "name",
                      value: skir.DataValue.wrapStringValue(name),
                    ),
                  ],
                ),
              );
          final original = source.copyWith(
            entries: {
              ...source.entries,
              dependency: entry(dependency, "Dependency"),
              unrelated: entry(unrelated, "Unrelated"),
            },
          );
          final transport = ScriptedAuthoringTransport(AsyncData(original));
          final submissions = ScopedWorkSession();
          final workspace = RealmEditing(
            persistence: transport.persistence,
            submissions: submissions,
            initial: original,
          );
          final binding = workspace.attach(
            _resource,
            policy: EditorCommitPolicy.applyResource,
          );
          addTearDown(binding.detach);
          addTearDown(workspace.dispose);
          addTearDown(submissions.dispose);
          addTearDown(transport.dispose);
          final material =
              (skir.PresentationMaterial.mutable()
                    ..provider = skir.PresentationId(
                      namespace: "test",
                      name: "query",
                    )
                    ..role = skir.PresentationRole.inspector
                    ..target = skir.PresentationTarget.createNamed(
                      definition: _page,
                      arguments: const [],
                    )
                    ..subject = skir.TypeTemplate.createNamed(
                      definition: _page,
                      arguments: const [],
                    ))
                  .toFrozen();
          final host = AuthoredPresentationHost(
            resource: _resource,
            source: original,
            material: material,
            role: skir.PresentationRole.inspector,
            budget: _budget,
            capabilities: const PortablePresentationCapabilities(),
            edit: binding,
          );
          addTearDown(host.dispose);
          final configured = skir.ExpressionBindingId(
            value: "configured_value",
          );
          final value = skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse(
              definition: _page,
              arguments: const [],
            ),
            payload: skir.DataValue.createRecord(
              fields: original.resource(_resource)!.fields,
            ),
          );
          final context = PortableInvocationContext(
            bindings: {
              configured: PortableExpressionBinding(
                value: value,
                location: skir.ValueLocation(
                  resource: _resource,
                  path: editorRootPath,
                ),
                schema: CompletePortablePresentationBinding(
                  skir.TypeUse.createNamed(
                    definition: _page,
                    arguments: const [],
                  ),
                ),
              ),
              _id: dependency.toExpressionBinding(),
            },
            catalogGeneration: original.generation,
            queries: PortableExpressionQueries(
              catalog: catalog,
              authored: original,
            ),
          );
          final changed = changedDependency ? dependency : unrelated;
          final concurrent = workspace.edit(
            label: "Concurrent edit",
            apply: (operation) => operation.set(
              skir.ValueLocation(resource: changed, path: _namePath),
              skir.DataValue.wrapStringValue("Changed"),
            ),
            from: original,
          );
          expect(concurrent, isA<EditStaged>());
          final expression = fieldExpression(
            _query(skir.ExpressionQuery.wrapResourceValue),
            "name",
          );
          final target = skir.BindingRef(
            bindingId: configured,
            path: _namePath,
          );
          final PortablePresentationWriteResult result;
          if (directWrite) {
            final evaluated = catalog.evaluateExpression(
              expression,
              bindings: context.bindings,
              budget: _budget,
              queries: context.queries,
            ) as PortableExpressionAvailable;
            result = await host.write(
              target,
              evaluated.value,
              context: context.withExpressionReads(evaluated.reads),
            );
          } else {
            result = await host.execute(
              skir.EditorAction.wrapLocal(
                skir.LocalEditorAction.createSetValue(
                  target: target,
                  value: expression,
                ),
              ),
              context: context,
            );
          }
          if (changedDependency) {
            expect(result, isA<PortablePresentationWriteRejected>());
            expect(
              workspace.document
                  .resource(_resource)!
                  .authoredField("name")!
                  .authoredString,
              "Original",
            );
          } else {
            expect(result, isA<PortablePresentationWriteApplied>());
            expect(
              workspace.document
                  .resource(_resource)!
                  .authoredField("name")!
                  .authoredString,
              "Dependency",
            );
            expect(
              workspace.document
                  .resource(unrelated)!
                  .authoredField("name")!
                  .authoredString,
              "Changed",
            );
          }
        },
      );
    }
  }
  test("canonical schema adapters round trip complete scalar and pending selections", () {
    final values = [
      skir.TypeUse.wrapScalar(
        skir.ScalarKind.createInteger(
          width: skir.IntegerWidth.unsignedSixtyFour,
        ),
      ),
      skir.TypeUse.wrapScalar(
        skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
      ),
      skir.TypeUse.createNullable(
        value: skir.TypeUse.createNamed(definition: _page, arguments: [_text]),
      ),
    ];
    for (final value in values) {
      final encoded = canonicalReadModels.project(
        value,
        skir.TypeUse.serializer.typeDescriptor,
        const [],
        () {},
        (_) {},
      );
      expect(canonicalReadModels.decodeTypeUse(encoded), value);
    }
    final selection = skir.TypeSelection.createPending(
      definition: _page,
      arguments: [
        skir.ArgumentSelection.wrapChosen(_text),
        skir.ArgumentSelection.unfilled,
      ],
    );
    final encoded = canonicalReadModels.project(
      selection,
      skir.TypeSelection.serializer.typeDescriptor,
      const [],
      () {},
      (_) {},
    );
    expect(canonicalReadModels.decodeTypeSelection(encoded), selection);
  });

  test(
    "a present unavailable declaration remains readable as canonical metadata",
    () {
      final original = _catalog();
      final catalog = CheckedEditorCatalog(
        (original.snapshot.toMutable()
              ..types = [
                for (final type in original.snapshot.types)
                  if (type.definition.id == _page)
                    (type.toMutable()
                          ..status = skir.DeclarationStatus.wrapUnavailable(
                            const [],
                          ))
                        .toFrozen()
                  else
                    type,
              ])
            .toFrozen(),
      );
      final selection = skir.TypeSelection.createComplete(
        definition: _page,
        arguments: const [],
      );
      final encoded = canonicalReadModels.project(
        selection,
        skir.TypeSelection.serializer.typeDescriptor,
        const [],
        () {},
        (_) {},
      );
      final expression = fieldExpression(
        fieldExpression(
          skir.ExpressionNode.wrapQuery(
            skir.ExpressionQuery.wrapCatalogDeclaration(
              literalExpression(encoded),
            ),
          ),
          "display",
        ),
        "name",
      );
      final result = catalog.evaluateExpression(
        expression,
        bindings: const {},
        budget: _budget,
        queries: PortableExpressionQueries(catalog: catalog),
      );
      expect(
        result,
        isA<PortableExpressionAvailable>(),
        reason: result is PortableExpressionFailed ? result.message : "$result",
      );
      expect(
        (result as PortableExpressionAvailable).value.authoredString,
        "Page",
      );
    },
  );

  test("malformed resource content does not become fallback text", () {
    final catalog = _catalog();
    final original = _document(catalog, "Page");
    final record = original.entry(_resource)!;
    final document = original.copyWith(
      entries: {
        _resource:
            (record.toMutable()
                  ..content =
                      (record.content.toMutable()
                            ..fields = [
                              skir.FieldValue(
                                name: "name",
                                value: skir.DataValue.wrapBoolean(true),
                              ),
                            ])
                          .toFrozen())
                .toFrozen(),
      },
    );
    final expression = skir.ExpressionNode.createOrElse(
      input: fieldExpression(
        _query(skir.ExpressionQuery.wrapResourceValue),
        "name",
      ),
      fallback: literalExpression(skir.DataValue.wrapStringValue("fallback")),
    );
    final result = catalog.evaluateExpression(
      expression,
      bindings: _bindings,
      budget: _budget,
      queries: PortableExpressionQueries(catalog: catalog, authored: document),
    );
    expect(result, isA<PortableExpressionFailed>());
    expect((result as PortableExpressionFailed).code, "invalid_resource_value");
  });
  test("admission rejects duplicate caller imports", () {
    final catalog = _catalog();
    final material = _resultMaterial(
      presentationText("body", textLiteral("Title")),
    );
    final id = skir.ExpressionBindingId(value: "context:test.origin");
    final dependency = skir.PresentationContextInput(
      source: skir.PresentationContextSource.caller,
      bindingId: id,
      valueType: skir.TypeUse.wrapNamed(frameworkResourceIdUse),
    );
    final conflicting =
        (material.toMutable()
              ..dependencies =
                  (material.dependencies.toMutable()
                        ..contextInputs = [dependency, dependency])
                      .toFrozen())
            .toFrozen();
    expect(
      catalog.presentationExpressionProblems(conflicting, _pageSelection),
      contains("duplicate_context_input"),
    );
  });

  test("admission accepts host imports only with the host contract's type", () {
    final catalog = _catalog();
    final id = skir.ExpressionBindingId(value: "context:host.active");
    skir.PresentationMaterial importing(skir.TypeUse type) {
      final material = _resultMaterial(
        presentationText("body", textLiteral("Title")),
      );
      return (material.toMutable()
            ..dependencies =
                (material.dependencies.toMutable()
                      ..contextInputs = [
                        skir.PresentationContextInput(
                          bindingId: id,
                          source: skir.PresentationContextSource.wrapHost(
                            skir.HostContextInput.activeResource,
                          ),
                          valueType: type,
                        ),
                      ])
                    .toFrozen())
          .toFrozen();
    }

    expect(
      catalog.presentationExpressionProblems(
        importing(skir.TypeUse.wrapScalar(skir.ScalarKind.text)),
        _pageSelection,
      ),
      contains("invalid_host_context_input"),
    );
    expect(
      catalog.presentationExpressionProblems(
        importing(skir.TypeUse.wrapNamed(frameworkResourceIdUse)),
        _pageSelection,
      ),
      isNot(contains("invalid_host_context_input")),
    );
  });

  test("a resource presentation reads its subject appearance", () {
    final catalog = _catalog();
    final label = presentationText(
      "label",
      inputExpression(presentationSubjectAppearanceBindingId, field: "label"),
    );
    final missing = presentationText(
      "missing",
      inputExpression(presentationSubjectAppearanceBindingId, field: "title"),
    );
    expect(
      catalog.presentationExpressionProblems(
        _resultMaterial(label),
        _pageSelection,
      ),
      isEmpty,
    );
    expect(
      catalog.presentationExpressionProblems(
        _resultMaterial(missing),
        _pageSelection,
      ),
      isNotEmpty,
    );
  });

  test("admission checks the paint of stacks, transforms and containers", () {
    final catalog = _catalog();
    final selected = skir.PresentationStateMatch(
      required_: [skir.PresentationInteractionState.selected],
      excluded: const [],
    );
    skir.PresentationNumber number(double value) =>
        skir.PresentationNumber.wrapValue(numberLiteral(value));
    final body = presentationText("body", textLiteral("Cover"));
    List<String> problems(skir.PresentationElement element) =>
        catalog.presentationExpressionProblems(
          _resultMaterial(presentationNode("paint", element)),
          _pageSelection,
        );

    final valid = skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createStack(
        alignment: null,
        children: [
          skir.StackChild.wrapFlow(body),
          skir.StackChild.createPositioned(
            child: body,
            top: number(4),
            start: null,
            end: skir.PresentationNumber.createStates(
              rules: [
                skir.PresentationStateNumberRule(
                  match: selected,
                  value: numberLiteral(8),
                ),
              ],
              fallback: numberLiteral(2),
            ),
            bottom: null,
            width: number(30),
            height: null,
            transition: skir.PresentationTransitionPolicy(
              rules: [
                skir.PresentationStateTransitionRule(
                  match: selected,
                  transition: skir.PresentationTransition(
                    milliseconds: 750,
                    curve: skir.PresentationCurve.wrapElasticOut(0.9),
                  ),
                ),
              ],
              fallback: skir.PresentationTransition(
                milliseconds: 300,
                curve: skir.PresentationCurve.emphasized,
              ),
            ),
          ),
        ],
      ),
    );
    expect(problems(valid), isEmpty);

    final overconstrained = skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createStack(
        alignment: null,
        children: [
          skir.StackChild.createPositioned(
            child: body,
            top: null,
            start: number(0),
            end: number(0),
            bottom: null,
            width: number(10),
            height: null,
            transition: null,
          ),
        ],
      ),
    );
    expect(
      problems(overconstrained),
      contains("overconstrained_positioned_child"),
    );

    final transform = skir.PresentationElement.createTransform(
      child: body,
      origin: skir.PresentationAlignment.center,
      perspective: double.nan,
      scale: skir.PresentationNumber.wrapValue(textLiteral("large")),
      rotateX: null,
      rotateY: null,
      rotateZ: null,
      translateX: null,
      translateY: null,
      transition: skir.PresentationTransitionPolicy(
        rules: [
          skir.PresentationStateTransitionRule(
            match: skir.PresentationStateMatch(
              required_: [skir.PresentationInteractionState.hovered],
              excluded: [skir.PresentationInteractionState.hovered],
            ),
            transition: skir.PresentationTransition(
              milliseconds: 10,
              curve: skir.PresentationCurve.linear,
            ),
          ),
        ],
        fallback: skir.PresentationTransition(
          milliseconds: -1,
          curve: skir.PresentationCurve.wrapElasticOut(0),
        ),
      ),
    );
    expect(
      problems(transform),
      containsAll([
        "invalid_transform_perspective",
        "contradictory_presentation_state_match",
        "invalid_presentation_transition",
        "invalid_presentation_curve",
      ]),
    );
    expect(problems(transform).length, greaterThan(4));

    final accent = skir.PresentationColor.wrapValue(integerLiteral(0xff3366cc));
    final container = skir.PresentationElement.createContainer(
      child: body,
      border: null,
      backgroundColor: skir.PresentationColor.createBrightness(
        light: skir.PresentationColor.createAdjusted(
          source: accent,
          lightness: 1.5,
          chroma: 0,
        ),
        dark: accent,
      ),
      radius: skir.PresentationRadius.large,
      foregroundColor: null,
      transition: null,
      shadows: [
        skir.PresentationShadow(
          color: accent,
          blur: -2,
          spread: 0,
          offsetX: 0,
          offsetY: 1,
        ),
      ],
    );
    expect(
      problems(container),
      containsAll([
        "invalid_presentation_color_adjustment",
        "invalid_presentation_shadow",
      ]),
    );
    expect(
      problems(
        skir.PresentationElement.createSize(
          child: body,
          width: textLiteral("wide"),
          height: numberLiteral(8),
          minimumWidth: null,
          maximumWidth: null,
          minimumHeight: null,
          maximumHeight: null,
        ),
      ),
      isNotEmpty,
    );
  });

  test("clipped axes reject flexible children and columns at admission", () {
    final catalog = _catalog();
    final child = presentationText(
      "child",
      literalExpression(skir.DataValue.wrapStringValue("Content")),
    );
    final clipped = (skir.AxisChildrenLayout.mutable()..clipOverflow = true)
        .toFrozen();
    final row =
        (skir.PresentationNode.mutable()
              ..nodeId = "row"
              ..element = skir.PresentationElement.wrapChildren(
                skir.ChildrenElement.createRow(
                  children: [
                    skir.AxisChild.createFlexible(
                      child: child,
                      flex: 1,
                      fit: skir.FlexFit.loose,
                    ),
                  ],
                  layout: clipped,
                ),
              ))
            .toFrozen();
    final column =
        (skir.PresentationNode.mutable()
              ..nodeId = "column"
              ..element = skir.PresentationElement.wrapChildren(
                skir.ChildrenElement.createColumn(
                  children: [skir.AxisChild.wrapFixed(child)],
                  layout: clipped,
                ),
              ))
            .toFrozen();
    final selection = skir.TypeSelection.createComplete(
      definition: _page,
      arguments: const [],
    );
    expect(
      catalog.presentationExpressionProblems(_resultMaterial(row), selection),
      contains("clipped_row_has_flexible_child"),
    );
    expect(
      catalog.presentationExpressionProblems(
        _resultMaterial(column),
        selection,
      ),
      contains("clipped_column_not_supported"),
    );
  });
  test("named payload configuration and projected writes preserve one identity and reads", () async {
    final original = _catalog();
    final alias = _definition("Label");
    final use = skir.NamedTypeUse(definition: alias, arguments: const []);
    final catalog = CheckedEditorCatalog(
      (original.snapshot.toMutable()
            ..types = [
              ...original.snapshot.types,
              _published(
                skir.TypeDefinition(
                  id: alias,
                  parameters: const [],
                  parents: const [],
                  representation: skir.RepresentationTemplate.createScalar(
                    kind: skir.ScalarKind.text,
                  ),
                ),
              ),
            ])
          .toFrozen(),
    );
    final operations = PortableOperationResults();
    addTearDown(operations.dispose);
    final host = BoundPresentationHost(
      catalog: catalog,
      root: () => presentationText(
        "label",
        literalExpression(skir.DataValue.wrapStringValue("Label")),
      ),
      bindings: const [],
      budget: _budget,
    );
    addTearDown(host.dispose);
    final configured = skir.ExpressionBindingId(value: "configured_value");
    final root = skir.BindingRef(bindingId: configured, path: editorRootPath);
    skir.DataValue? written;
    List<PortableExpressionRead>? observed;
    final payload = PortableNamedPayload(
      reference: root,
      actualType: use,
      value: skir.DataValue.wrapStringValue("Old"),
      location: skir.ValueLocation(resource: _resource, path: _namePath),
      bindings: const {},
      budget: _budget,
      setBinding:
          (reference, value, {reads = const <PortableExpressionRead>[]}) {
            written = value;
            observed = reads.toList();
            return const PortablePresentationWriteApplied();
          },
    );
    final scope = PortablePresentationScope(
      bindings: const {},
      budget: _budget,
      operations: operations,
      host: host,
      catalog: catalog,
      queries: PortableExpressionQueries(catalog: catalog),
    ).withNamedPayload(payload);
    final result = scope.evaluate(
      skir.ExpressionNode.wrapQuery(
        skir.ExpressionQuery.wrapValueConfiguration(
          skir.ExpressionNode.createInput(
            binding: configured,
            path: editorRootPath,
          ),
        ),
      ),
    );
    expect(result, isA<PortableExpressionAvailable>());
    expect(
      canonicalReadModels.decodeTypeSelection(
        (result as PortableExpressionAvailable).value,
      ),
      skir.TypeSelection.wrapComplete(use),
    );
    final reads = [
      PortableExpressionRead(
        source: PortableExpressionReadSource.input(configured),
        path: _namePath,
        location: skir.ValueLocation(resource: _resource, path: _namePath),
      ),
    ];
    final applied = await scope.apply(
      root,
      skir.DataValue.createNamed(
        actualType: use,
        payload: skir.DataValue.wrapStringValue("New"),
      ),
      reads: reads,
    );
    expect(applied, isA<PortablePresentationWriteApplied>());
    expect(
      written,
      skir.DataValue.createNamed(
        actualType: use,
        payload: skir.DataValue.wrapStringValue("New"),
      ),
    );
    expect(observed, reads);
    final rejected = await scope.apply(root, _resource.toExpressionValue());
    expect(rejected, isA<PortablePresentationWriteRejected>());
    expect(
      written,
      skir.DataValue.createNamed(
        actualType: use,
        payload: skir.DataValue.wrapStringValue("New"),
      ),
    );
  });
}

final _resource = skir.ResourceId(value: "page");
final _id = skir.ExpressionBindingId(value: "resource");
final _page = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "Page"),
  revision: 1,
);
final _other = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "Other"),
  revision: 1,
);
final _text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _budget = skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000);
Map<skir.ExpressionBindingId, PortableExpressionBinding> get _bindings => {
  _id: _resource.toExpressionBinding(),
};

PortableExpressionAvailable _evaluate(
  CheckedEditorCatalog catalog,
  AuthoringDocument document,
  skir.ExpressionNode expression,
) {
  final result = catalog.evaluateExpression(
    expression,
    bindings: _bindings,
    budget: _budget,
    queries: PortableExpressionQueries(catalog: catalog, authored: document),
  );
  expect(
    result,
    isA<PortableExpressionAvailable>(),
    reason: result is PortableExpressionFailed
        ? "${result.code}: ${result.message}"
        : "$result",
  );
  return result as PortableExpressionAvailable;
}

skir.ExpressionNode _query(
  skir.ExpressionQuery Function(skir.ResourceQuerySource) query, {
  bool generic = false,
}) => skir.ExpressionNode.wrapQuery(
  query(
    skir.ResourceQuerySource.createIdentity(
      identity: skir.ExpressionNode.createInput(
        binding: _id,
        path: editorRootPath,
      ),
      target: skir.TypeUse.createNamed(
        definition: _page,
        arguments: generic ? [_text] : const [],
      ),
    ),
  ),
);

CheckedEditorCatalog _catalog({bool generic = false, bool display = true}) {
  final name = skir.FieldDeclaration(
    owner: skir.FieldOwner(definition: _page, name: "name"),
    type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
    overrides: const [],
    hasConstructorDefault: false,
  );
  final page = skir.TypeDefinition(
    id: _page,
    parameters: generic
        ? [
            skir.TypeParameter(
              key: skir.ParameterKey(owner: _page, index: 0),
              name: "T",
              bounds: const [],
            ),
          ]
        : const [],
    representation: skir.RepresentationTemplate.createRecord(
      fields: [name],
      abstract_: false,
    ),
    parents: const [],
  );
  final other = skir.TypeDefinition(
    id: _other,
    parameters: const [],
    representation: skir.RepresentationTemplate.createRecord(
      fields: const [],
      abstract_: false,
    ),
    parents: const [],
  );
  final resourceId = skir.TypeDefinition(
    id: frameworkResourceIdUse.definition,
    parameters: const [],
    representation: skir.RepresentationTemplate.createScalar(
      kind: skir.ScalarKind.text,
    ),
    parents: const [],
  );
  return testCheckedCatalog(
    types: [
      _published(
        page,
        display: display
            ? skir.TypeDisplay(
                name: "Page",
                description: "Page type",
                icon: skir.Icon.wrapIconify("page"),
                color: skir.Color(argb: 0xff336699.toSigned(32)),
              )
            : null,
      ),
      _published(other),
      _published(resourceId),
    ],
  );
}

skir.PublishedType _published(
  skir.TypeDefinition definition, {
  skir.TypeDisplay? display,
}) => skir.PublishedType(
  searchKey: null,
  placementField: null,
  definition: definition,
  status: skir.DeclarationStatus.ready,
  effectiveFields: [
    if (definition.representation
        case skir.RepresentationTemplate_recordWrapper(:final value))
      for (final field in value.fields)
        skir.EffectiveFieldTemplate(
          key: field.owner.name,
          owner: field.owner,
          type: field.type,
          rules: const [],
        ),
  ],
  ancestorTemplates: definition.parents,
  display: display ?? defaultTypeDisplay(""),
);
AuthoringDocument _document(
  CheckedEditorCatalog catalog,
  String name, {
  skir.TypeSelection? configuration,
}) => AuthoringDocument(
  catalog: catalog,
  entries: {
    _resource: skir.AuthoringResource(
      id: _resource,
      content: skir.AuthoringRecord(
        configuration:
            configuration ??
            skir.TypeSelection.createComplete(
              definition: _page,
              arguments: const [],
            ),
        fields: [
          skir.FieldValue(
            name: "name",
            value: skir.DataValue.wrapStringValue(name),
          ),
        ],
      ),
    ),
  },
  links: const [],
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);
skir.PublishedType _referencePublished(
  skir.TypeDefinitionId id,
  skir.TypeDefinitionId target,
) => _published(
  skir.TypeDefinition(
    id: id,
    parameters: const [],
    parents: const [],
    representation: skir.RepresentationTemplate.createLink(
      endpoint: skir.EndpointId(value: "target"),
      target: skir.TypeTemplate.createNamed(
        definition: target,
        arguments: const [],
      ),
    ),
  ),
);
PortableExpressionBinding _referenceBinding(
  skir.TypeDefinitionId ref,
  skir.ResourceId target,
) {
  final use = skir.NamedTypeUse(definition: ref, arguments: const []);
  return PortableExpressionBinding(
    schema: CompletePortablePresentationBinding(
      skir.TypeUse.createNamed(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "typewriter",
            name: "List",
          ),
          revision: 1,
        ),
        arguments: [skir.TypeUse.wrapNamed(use)],
      ),
    ),
    value: skir.DataValue.createListValue(
      items: [
        skir.ListItem(
          id: skir.ItemId(value: "one"),
          value: skir.DataValue.createNamed(
            actualType: use,
            payload: skir.DataValue.createLink(
              endpoint: skir.EndpointId(value: "target"),
              target: skir.LinkTarget(
                resource: target,
                opposite: skir.ValuePath(
                  segments: [skir.PathSegment.createField(name: "reciprocal")],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final _namePath = skir.ValuePath(
  segments: [skir.PathSegment.createField(name: "name")],
);

final _pageSelection = skir.TypeSelection.createComplete(
  definition: _page,
  arguments: const [],
);

skir.PresentationMaterial _resultMaterial(skir.PresentationNode layout) =>
    (skir.PresentationMaterial.mutable()
          ..provider = skir.PresentationId(namespace: "test", name: "result")
          ..role = skir.PresentationRole.resourceSearchResult
          ..target = skir.PresentationTarget.createNamed(
            definition: _page,
            arguments: const [],
          )
          ..subject = skir.TypeTemplate.createNamed(
            definition: _page,
            arguments: const [],
          )
          ..layout = layout)
        .toFrozen();
