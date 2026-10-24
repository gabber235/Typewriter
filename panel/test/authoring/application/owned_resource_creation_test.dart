import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

void main() {
  test("ambient preferences are the selection, then the routed resource and every owner above it", () {
    final page = skir.ResourceId(value: "page:owned");
    final tag = skir.ResourceId(value: "tag:selected");
    final document = fixtureAuthoringDocument(
      realm: true,
      books: [
        Book(
          bookId: _book,
          title: "Owned",
          icon: "mdi:book",
          color: Colors.blue,
        ),
      ],
      pages: [Page(pageId: page, bookId: _book, name: "Intro")],
      tags: [Tag(tagId: tag, name: "Selected", color: Colors.green)],
    );
    final ambient = Provider(
      (ref) => ambientCreationResources(ref, _scope, document),
    );
    final container = ProviderContainer(
      overrides: [
        realmIdProvider.overrideWith((_) => _scope.realmId),
        routedResourceIdProvider.overrideWith((_) => page),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectionProvider.notifier).selectAll([
      AuthoringResourceIdentifier.inScope(_scope, tag),
    ]);

    expect(container.read(ambient), [
      tag,
      page,
      _book,
      fixtureLibraryId,
      fixtureRealmRootId,
    ]);
  });

  test(
    "a create action resolves its owner and evaluates its presets",
    () async {
      final document = _document();
      final group = skir.ExpressionBindingId(value: "group");
      final created =
          <
            (skir.TypeDefinitionId, skir.ValueLocation?, List<skir.FieldValue>)
          >[];
      final dispatcher = ResourceActionDispatcher(
        catalog: document.catalog,
        context: PortableInvocationContext(
          bindings: {
            configuredValueBindingId: PortableExpressionBinding(
              value: skir.DataValue.createRecord(
                fields: document.resource(_book)!.fields,
              ),
              location: skir.ValueLocation(
                resource: _book,
                path: editorRootPath,
              ),
            ),
            group: PortableExpressionBinding(
              value: skir.DataValue.createRecord(
                fields: [
                  skir.FieldValue(
                    name: "path",
                    value: skir.DataValue.wrapStringValue("act1.intro"),
                  ),
                ],
              ),
            ),
          },
          catalogGeneration: document.generation,
        ),
        isCurrent: () => true,
        navigate: (_, _) async {},
        prepare: (_, _, _) async {},
        create: (type, owner, supplied) async =>
            created.add((type, owner, supplied)),
      );

      await dispatcher.dispatch(
        skir.EditorAction.createCreate(
          type: fixtureResourceType("page"),
          owner: skir.BindingRef(
            bindingId: configuredValueBindingId,
            path: editorRootPath.field("pages"),
          ),
          fields: [
            skir.CreateFieldValue(
              path: editorRootPath.field("chapter"),
              value: skir.ExpressionNode.createInput(
                binding: group,
                path: editorRootPath.field("path"),
              ),
            ),
            // Missing presets leave their field at its creation default.
            skir.CreateFieldValue(
              path: editorRootPath.field("name"),
              value: skir.ExpressionNode.createInput(
                binding: group,
                path: editorRootPath.field("name"),
              ),
            ),
          ],
        ),
      );

      final (type, owner, supplied) = created.single;
      expect(type, fixtureResourceType("page"));
      expect(
        owner,
        skir.ValueLocation(
          resource: _book,
          path: editorRootPath.field("pages"),
        ),
      );
      expect(supplied, [
        skir.FieldValue(
          name: "chapter",
          value: skir.DataValue.wrapStringValue("act1.intro"),
        ),
      ]);
    },
  );

  test("nested preset paths build partial records", () {
    expect(
      presetFields([
        (
          editorRootPath.field("placement").field("x"),
          skir.DataValue.wrapInteger("2"),
        ),
        (editorRootPath.field("name"), skir.DataValue.wrapStringValue("Intro")),
      ]),
      [
        skir.FieldValue(
          name: "placement",
          value: skir.DataValue.createRecord(
            fields: [
              skir.FieldValue(
                name: "x",
                value: skir.DataValue.wrapInteger("2"),
              ),
            ],
          ),
        ),
        skir.FieldValue(
          name: "name",
          value: skir.DataValue.wrapStringValue("Intro"),
        ),
      ],
    );
  });

  testWidgets("a new Book joins the single Library without asking", (
    tester,
  ) async {
    final result = await _create(
      tester,
      ResourceCreationRequest(
        type: fixtureResourceType("book"),
        configuration: _document().catalog.beginSelection(
          fixtureResourceType("book"),
        ),
        // The fixture prepares no nested records, so the icon is supplied.
        supplied: [
          skir.FieldValue(
            name: "icon",
            value: skir.DataValue.createNamed(
              actualType: skir.NamedTypeUse(
                definition: fixtureResourceType("icon"),
                arguments: const [],
              ),
              payload: skir.DataValue.createRecord(
                fields: [
                  skir.FieldValue(
                    name: "value",
                    value: skir.DataValue.wrapStringValue("mdi:book"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    expect(find.byType(SearchModal), findsNothing);
    final book = result.document.resource(result.created)!;
    expect(
      book.authoredField("library")?.authoredLink?.target.resource,
      fixtureLibraryId,
    );
    expect(
      result.document
          .resource(fixtureLibraryId)!
          .authoredField("books")!
          .authoredItems,
      hasLength(2),
    );
  });

  testWidgets(
    "a resource created into an owning field links to its owner with presets",
    (tester) async {
      final document = _document();
      final transport = ScriptedAuthoringTransport(AsyncData(document));
      addTearDown(transport.dispose);
      RealmEditing? workspace;
      AuthoringResourceIdentifier? created;
      Object? error;
      await tester.pumpTestApp(
        overrides: [
          organizationIdProvider.overrideWith((_) => _scope.organizationId),
          realmIdProvider.overrideWith((_) => _scope.realmId),
          ...authoringFixtureOverrides(
            scope: _scope,
            document: document,
            transport: transport,
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                workspace = ref.read(realmEditingProvider(_scope));
                try {
                  created = await ref
                      .read(resourceCreationProvider(_scope))
                      .create(
                        context: context,
                        request: ResourceCreationRequest(
                          type: fixtureResourceType("page"),
                          configuration: document.catalog.beginSelection(
                            fixtureResourceType("page"),
                          ),
                          supplied: [
                            skir.FieldValue(
                              name: "chapter",
                              value: skir.DataValue.wrapStringValue("act1"),
                            ),
                          ],
                        ),
                        creationContext: ownerCreationContext(
                          document,
                          skir.ValueLocation(
                            resource: _book,
                            path: editorRootPath.field("pages"),
                          ),
                        ),
                      );
                } on Object catch (caught) {
                  error = caught;
                }
              },
              child: const Text("Create"),
            ),
          ),
        ),
      );

      await tester.tap(find.text("Create"));
      await tester.pumpAndSettle();

      expect(error, isNull);
      expect(find.byType(SearchModal), findsNothing);
      final page = workspace!.document.resource(created!.resourceId)!;
      expect(page.authoredField("book")?.authoredLink?.target.resource, _book);
      expect(page.authoredField("chapter")?.authoredString, "act1");
      expect(
        workspace!.document
            .resource(_book)!
            .authoredField("pages")!
            .authoredItems,
        hasLength(1),
      );
    },
  );

  test("only owning link fields accept new owned resources", () {
    final document = _document();

    expect(
      () => ownerCreationContext(
        document,
        skir.ValueLocation(resource: _book, path: editorRootPath.field("tags")),
      ),
      throwsStateError,
    );
    expect(
      ownerCreationContext(
        document,
        skir.ValueLocation(
          resource: _book,
          path: editorRootPath.field("pages"),
        ),
      ).constraints,
      [
        CreationReferenceConstraint(
          route: [skir.EndpointId(value: "$fixtureBookPagesRelation:second")],
          targets: {_book},
        ),
      ],
    );
  });
}

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:owned"),
  realmId: skir.recordId("realm:owned"),
);
final _book = skir.ResourceId(value: "book:owned");

/// Creates [request] without an owner and returns the working document.
Future<({AuthoringDocument document, skir.ResourceId created})> _create(
  WidgetTester tester,
  ResourceCreationRequest request,
) async {
  final document = _document();
  final transport = ScriptedAuthoringTransport(AsyncData(document));
  addTearDown(transport.dispose);
  RealmEditing? workspace;
  AuthoringResourceIdentifier? created;
  await tester.pumpTestApp(
    overrides: [
      organizationIdProvider.overrideWith((_) => _scope.organizationId),
      realmIdProvider.overrideWith((_) => _scope.realmId),
      ...authoringFixtureOverrides(
        scope: _scope,
        document: document,
        transport: transport,
      ),
    ],
    child: Consumer(
      builder: (context, ref, _) => Scaffold(
        body: FilledButton(
          onPressed: () async {
            workspace = ref.read(realmEditingProvider(_scope));
            created = await ref
                .read(resourceCreationProvider(_scope))
                .create(context: context, request: request);
          },
          child: const Text("Create"),
        ),
      ),
    ),
  );
  await tester.tap(find.text("Create"));
  await tester.pumpAndSettle();
  return (document: workspace!.document, created: created!.resourceId);
}

AuthoringDocument _document() => fixtureAuthoringDocument(
  realm: true,
  books: [
    Book(bookId: _book, title: "Owned", icon: "mdi:book", color: Colors.blue),
  ],
);
