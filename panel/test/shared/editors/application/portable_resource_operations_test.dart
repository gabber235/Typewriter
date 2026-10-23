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
      final expression = fieldExpression(_resourceValue(), "name");
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
    final declaration = _declaration();
    final color = fieldExpression(
      fieldExpression(declaration, "display"),
      "color",
    );
    final result = _evaluate(catalog, _document(catalog, "Page"), color);
    expect(result.value, colorValue(0xff336699));
    expect(result.reads, [_resourceRoot]);
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
      final result = PortableExpressionEvaluator.located(
        _bindings,
        budget: _budget,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: document,
        ),
      ).evaluate(_resourceValue());
      expect(result, isA<PortableExpressionUnavailable>());
      expect((result as PortableExpressionUnavailable).locations, [
        _resourceRoot,
      ]);
      expect(result.reads, [_resourceRoot]);
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
    final name = fieldExpression(_resourceValue(generic: true), "name");
    expect(_evaluate(catalog, document, name).value.authoredString, "Pending");
    final declaration = _declaration();
    expect(
      _evaluate(
        catalog,
        document,
        fieldExpression(fieldExpression(declaration, "display"), "name"),
      ).value.authoredString,
      "Page",
    );
  });

  test("absent resources remain missing while an evaluation without an authoring observation fails", () {
    final catalog = _catalog();
    final expression = _resourceValue();
    final empty = AuthoringDocument(
      catalog: catalog,
      entries: const {},
      links: const [],
    );
    final result = PortableExpressionEvaluator.located(
      _bindings,
      budget: _budget,
      queries: PortableExpressionQueries(catalog: catalog, authored: empty),
    ).evaluate(expression);
    expect(result, isA<PortableExpressionUnavailable>());
    expect((result as PortableExpressionUnavailable).locations, [
      _resourceRoot,
    ]);
    expect(result.reads, [_resourceRoot]);
    final unsupported = PortableExpressionEvaluator.located(
      _bindings,
      budget: _budget,
      catalog: catalog,
    ).evaluate(expression);
    expect(unsupported, isA<PortableExpressionFailed>());
    expect(
      (unsupported as PortableExpressionFailed).failure,
      skir.PortableFailures.outsideRuleProfile,
    );
  });

  test(
    "unknown fields are missing and an undeclared display reads the defaults",
    () {
      final catalog = _catalog(display: false);
      final document = _document(catalog, "Page");
      final declaration = _declaration();
      final expression = skir.ExpressionNode.createOrElse(
        value: fieldExpression(
          fieldExpression(declaration, "display"),
          "color",
        ),
        fallback: literalExpression(colorValue(0xff123456)),
      );
      expect(
        _evaluate(catalog, document, expression).value,
        colorValue(0xff607d8b),
      );
      final unknown = PortableExpressionEvaluator.located(
        _bindings,
        budget: _budget,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: document,
        ),
      ).evaluate(fieldExpression(declaration, "unknown"));
      expect(unknown, isA<PortableExpressionUnavailable>());
      expect((unknown as PortableExpressionUnavailable).locations, isEmpty);
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
  test("lambda locals read the resources of links of different types", () {
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
      portableCall("resource.value", [
        skir.ExpressionNode.createLocal(
          depth: 0,
          slot: 0,
          path: editorRootPath,
        ),
      ]),
      "name",
    );
    skir.ExpressionNode mapped(skir.ExpressionBindingId source) =>
        portableCall("collection.map", [
          skir.ExpressionNode.createOrElse(
            value: skir.ExpressionNode.createInput(
              binding: source,
              path: editorRootPath,
            ),
            fallback: literalExpression(
              skir.DataValue.createListValue(items: const []),
            ),
          ),
          skir.ExpressionNode.createLambda(arity: 1, body: body),
        ]);
    final empty = literalExpression(skir.DataValue.wrapStringValue(""));
    skir.ExpressionNode join(skir.ExpressionNode source) =>
        portableCall("text.join", [source, empty]);
    final result =
        PortableExpressionEvaluator.located(
          {
            left: _referenceBinding(pageRef, _resource),
            right: _referenceBinding(otherRef, other),
          },
          budget: _budget,
          queries: PortableExpressionQueries(
            catalog: catalog,
            authored: document,
          ),
        ).evaluate(
          join(
            portableCall("list.of", [join(mapped(left)), join(mapped(right))]),
          ),
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
      final reference = skir.TypeTemplate.createNamed(
        definition: ref,
        arguments: const [],
      );
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
        declareBinding(item, reference),
      )!;
      final aliasScope = itemScope.withBinding(
        skir.BindingRef(bindingId: item, path: editorRootPath),
        declareBinding(alias, reference),
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
          portableCall("resource.value", [
            skir.ExpressionNode.createInput(
              binding: alias,
              path: editorRootPath,
            ),
          ]),
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
          final expression = fieldExpression(_resourceValue(), "name");
          final target = skir.BindingRef(
            bindingId: configured,
            path: _namePath,
          );
          final PortablePresentationWriteResult result;
          if (directWrite) {
            final evaluated = PortableExpressionEvaluator.located(
              context.bindings,
              budget: _budget,
              queries: context.queries,
            ).evaluate(expression) as PortableExpressionAvailable;
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
          portableCall("catalog.declaration", [literalExpression(encoded)]),
          "display",
        ),
        "name",
      );
      final result = PortableExpressionEvaluator.located(
        const {},
        budget: _budget,
        queries: PortableExpressionQueries(catalog: catalog),
      ).evaluate(expression);
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

  test(
    "trusted resource content is read as stored, not replaced by the fallback",
    () {
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
        value: fieldExpression(_resourceValue(), "name"),
        fallback: literalExpression(skir.DataValue.wrapStringValue("fallback")),
      );
      final result = PortableExpressionEvaluator.located(
        _bindings,
        budget: _budget,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: document,
        ),
      ).evaluate(expression);
      expect(result, isA<PortableExpressionAvailable>());
      expect(
        (result as PortableExpressionAvailable).value,
        skir.DataValue.wrapBoolean(true),
      );
    },
  );
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
    List<skir.ValueLocation>? observed;
    final payload = PortableNamedPayload(
      reference: root,
      actualType: use,
      value: skir.DataValue.wrapStringValue("Old"),
      location: skir.ValueLocation(resource: _resource, path: _namePath),
      setBinding: (reference, value, {reads = const <skir.ValueLocation>[]}) {
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
      portableCall("value.configuration", [
        skir.ExpressionNode.createInput(
          binding: configured,
          path: editorRootPath,
        ),
      ]),
    );
    expect(result, isA<PortableExpressionAvailable>());
    expect(
      canonicalReadModels.decodeTypeSelection(
        (result as PortableExpressionAvailable).value,
      ),
      skir.TypeSelection.wrapComplete(use),
    );
    final reads = [skir.ValueLocation(resource: _resource, path: _namePath)];
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

final _resourceRoot = skir.ValueLocation(
  resource: _resource,
  path: editorRootPath,
);

PortableExpressionAvailable _evaluate(
  CheckedEditorCatalog catalog,
  AuthoringDocument document,
  skir.ExpressionNode expression,
) {
  final result = PortableExpressionEvaluator.located(
    _bindings,
    budget: _budget,
    queries: PortableExpressionQueries(catalog: catalog, authored: document),
  ).evaluate(expression);
  expect(
    result,
    isA<PortableExpressionAvailable>(),
    reason: result is PortableExpressionFailed
        ? "${result.failure.value}: ${result.message}"
        : "$result",
  );
  return result as PortableExpressionAvailable;
}

skir.ExpressionNode get _identity =>
    skir.ExpressionNode.createInput(binding: _id, path: editorRootPath);

/// The configured value of the bound resource as a Page.
skir.ExpressionNode _resourceValue({bool generic = false}) => portableCall(
  "resource.value_of",
  [_identity],
  typeArguments: [
    skir.TypeTemplate.createNamed(
      definition: _page,
      arguments: generic
          ? [skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)]
          : const [],
    ),
  ],
);

/// The published declaration of the bound resource's configured type.
skir.ExpressionNode _declaration() => portableCall("catalog.declaration", [
  portableCall("resource.configuration", [_identity]),
]);

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
    id: skir.resourceIdType.definition,
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
