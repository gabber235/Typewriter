import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "canonical resource fields remain pinned across same generation documents",
    () {
      final catalog = boundPage.catalog();
      final first = boundPage.document(catalog, "First");
      final second = boundPage.document(catalog, "Second");
      final expression = fieldExpression(boundPage.valueOf(), "name");
      expect(
        boundPage.evaluate(catalog, first, expression).value.authoredString,
        "First",
      );
      expect(
        boundPage.evaluate(catalog, second, expression).value.authoredString,
        "Second",
      );
      expect(
        boundPage.evaluate(catalog, first, expression).value.authoredString,
        "First",
      );
    },
  );

  test("declaration color is read canonically without sibling projection", () {
    final catalog = boundPage.catalog();
    final declaration = boundPage.declaration;
    final color = fieldExpression(
      fieldExpression(declaration, "display"),
      "color",
    );
    final result = boundPage.evaluate(
      catalog,
      boundPage.document(catalog, "Page"),
      color,
    );
    expect(result.value, colorValue(0xff336699));
    expect(result.reads, [boundPage.root]);
  });

  test(
    "typed resource mismatch is missing and does not read another resource",
    () {
      final catalog = boundPage.catalog();
      final document = boundPage.document(
        catalog,
        "Different",
        configuration: skir.TypeSelection.createComplete(
          definition: boundPage.otherType,
          arguments: const [],
        ),
      );
      final result = PortableExpressionEvaluator.located(
        boundPage.bindings,
        budget: boundPage.budget,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: document,
        ),
      ).evaluate(boundPage.valueOf());
      expect(result, isA<PortableExpressionUnavailable>());
      expect((result as PortableExpressionUnavailable).locations, [
        boundPage.root,
      ]);
      expect(result.reads, [boundPage.root]);
    },
  );

  test("pending selections keep declaration metadata and known fields", () {
    final catalog = boundPage.catalog(generic: true);
    final document = boundPage.document(
      catalog,
      "Pending",
      configuration: skir.TypeSelection.createPending(
        definition: boundPage.type,
        arguments: const [skir.ArgumentSelection.unfilled],
      ),
    );
    final name = fieldExpression(boundPage.valueOf(generic: true), "name");
    expect(
      boundPage.evaluate(catalog, document, name).value.authoredString,
      "Pending",
    );
    final declaration = boundPage.declaration;
    expect(
      boundPage
          .evaluate(
            catalog,
            document,
            fieldExpression(fieldExpression(declaration, "display"), "name"),
          )
          .value
          .authoredString,
      "Page",
    );
  });

  test("absent resources remain missing while an evaluation without an authoring observation fails", () {
    final catalog = boundPage.catalog();
    final expression = boundPage.valueOf();
    final empty = AuthoringDocument(
      catalog: catalog,
      entries: const {},
      links: const [],
    );
    final result = PortableExpressionEvaluator.located(
      boundPage.bindings,
      budget: boundPage.budget,
      queries: PortableExpressionQueries(catalog: catalog, authored: empty),
    ).evaluate(expression);
    expect(result, isA<PortableExpressionUnavailable>());
    expect((result as PortableExpressionUnavailable).locations, [
      boundPage.root,
    ]);
    expect(result.reads, [boundPage.root]);
    final unsupported = PortableExpressionEvaluator.located(
      boundPage.bindings,
      budget: boundPage.budget,
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
      final catalog = boundPage.catalog(display: false);
      final document = boundPage.document(catalog, "Page");
      final declaration = boundPage.declaration;
      final expression = skir.ExpressionNode.createOrElse(
        value: fieldExpression(
          fieldExpression(declaration, "display"),
          "color",
        ),
        fallback: literalExpression(colorValue(0xff123456)),
      );
      expect(
        boundPage.evaluate(catalog, document, expression).value,
        colorValue(0xff607d8b),
      );
      final unknown = PortableExpressionEvaluator.located(
        boundPage.bindings,
        budget: boundPage.budget,
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
          form: skir.RecordForm.concrete,
        ),
        parents: const [],
      );
      expect(
        () => CheckedEditorCatalog(
          (skir.EditorCatalog.mutable()
                ..types = [declaredDefinition(definition)])
              .toFrozen(),
        ),
        throwsFormatException,
      );
    },
  );
  test("lambda locals read the resources of links of different types", () {
    final base = boundPage.catalog();
    final pageRef = typeDefinition("PageRef");
    final otherRef = typeDefinition("OtherRef");
    final otherName = skir.FieldDeclaration(
      owner: skir.FieldOwner(definition: boundPage.otherType, name: "name"),
      type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      overrides: const [],
      hasConstructorDefault: false,
    );
    final catalog = CheckedEditorCatalog(
      (base.snapshot.toMutable()
            ..types = [
              for (final type in base.snapshot.types)
                if (type.definition.id != boundPage.otherType) type,
              declaredDefinition(
                skir.TypeDefinition(
                  id: boundPage.otherType,
                  parameters: const [],
                  parents: const [],
                  representation: skir.RepresentationTemplate.createRecord(
                    fields: [otherName],
                    form: skir.RecordForm.concrete,
                  ),
                ),
              ),
              linkType(pageRef, boundPage.type),
              linkType(otherRef, boundPage.otherType),
            ])
          .toFrozen(),
    );
    final other = skir.ResourceId(value: "other");
    final original = boundPage.document(catalog, "First");
    final document = original.copyWith(
      entries: {
        ...original.entries,
        other: skir.AuthoringResource(
          id: other,
          content: skir.AuthoringRecord(
            types: const [],
            configuration: skir.TypeSelection.createComplete(
              definition: boundPage.otherType,
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
            left: linkListBinding(pageRef, boundPage.resource),
            right: linkListBinding(otherRef, other),
          },
          budget: boundPage.budget,
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
      final base = boundPage.catalog();
      final ref = typeDefinition("PageRef");
      final catalog = CheckedEditorCatalog(
        (base.snapshot.toMutable()
              ..types = [...base.snapshot.types, linkType(ref, boundPage.type)])
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
        bindings: {source: linkListBinding(ref, boundPage.resource)},
        budget: boundPage.budget,
        operations: operations,
        catalog: catalog,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: boundPage.document(catalog, "Aliased page"),
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
          final catalog = boundPage.catalog();
          final source = boundPage.document(catalog, "Original");
          final dependency = skir.ResourceId(value: "dependency");
          final unrelated = skir.ResourceId(value: "unrelated");
          skir.AuthoringResource entry(skir.ResourceId id, String name) =>
              skir.AuthoringResource(
                id: id,
                content: skir.AuthoringRecord(
                  types: const [],
                  configuration: skir.TypeSelection.createComplete(
                    definition: boundPage.type,
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
          final realm = FakeRealm(
            scope: AuthoringScope(
              organizationId: skir.recordId("organization:operations"),
              realmId: skir.recordId("realm_instance:operations"),
            ),
            name: "Operations",
            document: original,
          );
          final submissions = ScopedWorkSession();
          final workspace = RealmEditing(
            persistence: realm.persistence,
            submissions: submissions,
            initial: original,
          );
          final binding = workspace.form(boundPage.resource);
          addTearDown(workspace.dispose);
          addTearDown(submissions.dispose);
          addTearDown(realm.close);
          final material =
              (skir.PresentationMaterial.mutable()
                    ..provider = skir.PresentationId(
                      namespace: "test",
                      name: "query",
                    )
                    ..role = skir.PresentationRole.inspector
                    ..target = skir.PresentationTarget.createNamed(
                      definition: boundPage.type,
                      arguments: const [],
                    )
                    ..subject = skir.TypeTemplate.createNamed(
                      definition: boundPage.type,
                      arguments: const [],
                    ))
                  .toFrozen();
          final host = AuthoredPresentationHost(
            resource: boundPage.resource,
            source: original,
            material: material,
            role: skir.PresentationRole.inspector,
            budget: boundPage.budget,
            capabilities: const PortablePresentationCapabilities(),
            edit: binding,
          );
          addTearDown(host.dispose);
          final configured = skir.ExpressionBindingId(
            value: "configured_value",
          );
          final value = skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse(
              definition: boundPage.type,
              arguments: const [],
            ),
            payload: skir.DataValue.createRecord(
              fields: original.resource(boundPage.resource)!.fields,
            ),
          );
          final context = PortableInvocationContext(
            bindings: {
              configured: PortableExpressionBinding(
                value: value,
                location: skir.ValueLocation(
                  resource: boundPage.resource,
                  path: editorRootPath,
                ),
                schema: CompletePortablePresentationBinding(
                  skir.TypeUse.createNamed(
                    definition: boundPage.type,
                    arguments: const [],
                  ),
                ),
              ),
              boundPage.binding: dependency.toExpressionBinding(),
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
          final expression = fieldExpression(boundPage.valueOf(), "name");
          final target = skir.BindingRef(
            bindingId: configured,
            path: _namePath,
          );
          final PortablePresentationWriteResult result;
          if (directWrite) {
            final evaluated = PortableExpressionEvaluator.located(
              context.bindings,
              budget: boundPage.budget,
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
                  .resource(boundPage.resource)!
                  .authoredField("name")!
                  .authoredString,
              "Original",
            );
          } else {
            expect(result, isA<PortablePresentationWriteApplied>());
            expect(
              workspace.document
                  .resource(boundPage.resource)!
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
        value: skir.TypeUse.createNamed(
          definition: boundPage.type,
          arguments: [_text],
        ),
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
      definition: boundPage.type,
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
      final original = boundPage.catalog();
      final catalog = CheckedEditorCatalog(
        (original.snapshot.toMutable()
              ..types = [
                for (final type in original.snapshot.types)
                  if (type.definition.id == boundPage.type)
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
        definition: boundPage.type,
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
        budget: boundPage.budget,
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
      final catalog = boundPage.catalog();
      final original = boundPage.document(catalog, "Page");
      final record = original.entry(boundPage.resource)!;
      final document = original.copyWith(
        entries: {
          boundPage.resource:
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
        value: fieldExpression(boundPage.valueOf(), "name"),
        fallback: literalExpression(skir.DataValue.wrapStringValue("fallback")),
      );
      final result = PortableExpressionEvaluator.located(
        boundPage.bindings,
        budget: boundPage.budget,
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
    final original = boundPage.catalog();
    final alias = typeDefinition("Label");
    final use = skir.NamedTypeUse(definition: alias, arguments: const []);
    final catalog = CheckedEditorCatalog(
      (original.snapshot.toMutable()
            ..types = [
              ...original.snapshot.types,
              declaredDefinition(
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
      budget: boundPage.budget,
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
      location: skir.ValueLocation(
        resource: boundPage.resource,
        path: _namePath,
      ),
      setBinding: (reference, value, {reads = const <skir.ValueLocation>[]}) {
        written = value;
        observed = reads.toList();
        return const PortablePresentationWriteApplied();
      },
    );
    final scope = PortablePresentationScope(
      bindings: const {},
      budget: boundPage.budget,
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
    final reads = [
      skir.ValueLocation(resource: boundPage.resource, path: _namePath),
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
    final rejected = await scope.apply(
      root,
      boundPage.resource.toExpressionValue(),
    );
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

final _text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _namePath = skir.ValuePath(
  segments: [skir.PathSegment.createField(name: "name")],
);
