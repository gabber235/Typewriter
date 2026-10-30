import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("ambient preferences are the selection, then the routed "
      "resource and every owner above it", (tester) async {
    final owned = _owned;
    final intro = page("Intro", book: owned);
    final selected = tag("Selected");
    final panel = await tester.pumpPanel(
      [
        signedIn(ada, organization: acme),
        realm(books: [owned], pages: [intro], tags: [selected]),
      ],
      at: PanelLocation.route(
        const RealmRouteTree().surface(
          AuthoringScope(
            organizationId: acme.organizationId,
            realmId: skir.recordId("realm_instance:main"),
          ),
          SurfaceTarget.resource(routed: intro.pageId),
        ),
      ),
    );
    await panel.resources.selectOnly([selected.tagId]);
    final scope = panel.world.requireRealm.scope;

    final ambient = panel.container.read(
      Provider(
        (ref) => ambientCreationResources(ref, scope, panel.workingDocument),
      ),
    );

    expect(ambient, [
      selected.tagId,
      intro.pageId,
      owned.bookId,
      libraryId,
      realmRootId,
    ]);
  });

  test(
    "a create action resolves its owner and evaluates its presets",
    () async {
      final document = realmDocument(books: [_owned]);
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
                fields: document.resource(_owned.bookId)!.fields,
              ),
              location: skir.ValueLocation(
                resource: _owned.bookId,
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
          type: libraryType("page"),
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
      expect(type, libraryType("page"));
      expect(
        owner,
        skir.ValueLocation(
          resource: _owned.bookId,
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
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [_owned]),
    ]);
    final type = libraryType("book");

    final creation = await panel.create(
      ResourceCreationRequest(
        type: type,
        configuration: panel.workingDocument.catalog.beginSelection(type),
        // The Realm double prepares no nested records, so the icon is
        // supplied.
        supplied: [
          skir.FieldValue(
            name: "icon",
            value: skir.DataValue.createNamed(
              actualType: skir.NamedTypeUse(
                definition: libraryType("icon"),
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

    expect(creation.error, isNull);
    final created = creation.created!.resourceId;
    final document = panel.workingDocument;
    expect(
      document
          .resource(created)!
          .authoredField("library")
          ?.authoredLink
          ?.target
          .resource,
      libraryId,
    );
    expect(document.relations.children[libraryId], [_owned.bookId, created]);
  });

  testWidgets(
    "a resource created into an owning field links to its owner with presets",
    (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [_owned]),
      ]);
      final type = libraryType("page");
      final book = _owned.bookId;

      final creation = await panel.create(
        ResourceCreationRequest(
          type: type,
          configuration: panel.workingDocument.catalog.beginSelection(type),
          supplied: [
            skir.FieldValue(
              name: "chapter",
              value: skir.DataValue.wrapStringValue("act1"),
            ),
          ],
        ),
        context: ownerCreationContext(
          panel.workingDocument,
          skir.ValueLocation(
            resource: book,
            path: editorRootPath.field("pages"),
          ),
        ),
      );

      expect(creation.error, isNull);
      final document = panel.workingDocument;
      final page = document.resource(creation.created!.resourceId)!;
      expect(page.authoredField("book")?.authoredLink?.target.resource, book);
      expect(page.authoredField("chapter")?.authoredString, "act1");
      expect(document.relations.children[book], [creation.created!.resourceId]);
    },
  );

  test("only owning link fields accept new owned resources", () {
    final document = realmDocument(books: [_owned]);

    expect(
      () => ownerCreationContext(
        document,
        skir.ValueLocation(
          resource: _owned.bookId,
          path: editorRootPath.field("tags"),
        ),
      ),
      throwsStateError,
    );
    expect(
      ownerCreationContext(
        document,
        skir.ValueLocation(
          resource: _owned.bookId,
          path: editorRootPath.field("pages"),
        ),
      ).constraints,
      [
        CreationReferenceConstraint(
          route: [skir.EndpointId(value: "$bookPagesRelation:second")],
          targets: {_owned.bookId},
        ),
      ],
    );
  });
}

/// The Book the Realm starts with.
final _owned = book("Owned");
