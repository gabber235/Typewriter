import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "publication_fixture.dart";
import "realm_catalog_fixture.dart";
import "../shared/testing/testing.dart";

/// Controls replies and confirmed observations independently. It never simulates Realm mutations.
final class ScriptedAuthoringTransport extends ChangeNotifier {
  ScriptedAuthoringTransport(this.observation, {this.onRequest});
  AsyncValue<AuthoringDocument> observation;
  final void Function(skir.PreparedEdit edit)? onRequest;
  final requests = <ScriptedAuthoringRequest>[];
  Object? refreshFailure;
  int fetches = 0;
  RealmEditPersistence get persistence =>
      fixtureRealmPersistence(commit: commit, confirmed: fetchConfirmed);
  void publish(AsyncValue<AuthoringDocument> next) {
    observation = next;
    notifyListeners();
  }

  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) {
    final request = ScriptedAuthoringRequest(edit);
    requests.add(request);
    onRequest?.call(edit);
    notifyListeners();
    return request.response.future;
  }

  Future<AuthoringDocument> fetchConfirmed() async {
    fetches++;
    if (refreshFailure case final error?) throw error;
    return observation.requireValue;
  }

  void confirm(int request, AuthoringDocument confirmed) {
    publish(AsyncData(confirmed));
    requests[request].response.complete(
      skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
    );
  }

  void reject(int request, skir.CommitResult response) {
    if (response == skir.CommitResult.committed) {
      throw ArgumentError(
        "A committed reply requires an explicit confirmed document",
      );
    }
    requests[request].response.complete(
      skir.CommitPreparedEditResponse.wrapResult(response),
    );
  }

  void loseReply(int request, Object error) =>
      requests[request].response.completeError(error);
}

final class ScriptedAuthoringRequest {
  ScriptedAuthoringRequest(this.edit);
  final skir.PreparedEdit edit;
  final response = Completer<skir.CommitPreparedEditResponse>();
}

/// Fixtures replace external observations and capabilities. Production workspace and queries run unchanged.
/// Default publication repositories belong to each provider key. A supplied
/// [publication] must match that scope and remains owned by its caller.
List<Override> authoringFixtureOverrides({
  AuthoringScope? scope,
  DisplayState? state,
  AuthoringDocument? document,
  AuthoringSessionState? initial,
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  Iterable<Page> pages = const [],
  CheckedEditorCatalog? catalog,
  ScriptedAuthoringTransport? transport,
  AsyncValue<AuthoringDocument>? observation,
  TestPublicationRepository? publication,
  AuthoredResourceCommands? commands,
  AuthoredResourceCommands Function(Ref, ScriptedAuthoringTransport)?
  commandsFactory,
  void Function(skir.PreparedEdit edit)? onRequest,
}) {
  final source =
      document ??
      initial?.confirmedDocument ??
      fixtureAuthoringDocument(
        books: books,
        tags: tags,
        pages: pages,
        catalog: catalog,
      );
  final scripted =
      transport ??
      ScriptedAuthoringTransport(
        observation ??
            (state == DisplayState.loading
                ? const AsyncLoading<AuthoringDocument>()
                : state == DisplayState.error
                ? AsyncError<AuthoringDocument>(
                    StateError("Realm fixture unavailable"),
                    StackTrace.current,
                  )
                : initial?.failure != null
                ? AsyncError<AuthoringDocument>(
                    initial!.failure!,
                    StackTrace.current,
                  )
                : AsyncData(source)),
        onRequest: onRequest,
      );
  return [
    realmPublicationRepositoryProvider.overrideWith((ref, scopeIds) {
      final (organizationId, realmId) = scopeIds;
      final requested = AuthoringScope(
        organizationId: organizationId,
        realmId: realmId,
      );
      final supplied = publication;
      if (supplied != null) {
        if (supplied.scope != requested) {
          throw StateError(
            "Publication fixture scope does not match the requested realm",
          );
        }
        return supplied;
      }
      final repository = TestPublicationRepository(
        requested,
        initial: PublicationObservation.available(
          skir.PublicationView(
            id: skir.PublicationViewId(value: "fixture:empty"),
            status: skir.PublicationStatus.createEmpty(notices: const []),
          ),
        ),
      );
      ref.onDispose(() => unawaited(repository.close()));
      return repository;
    }),
    selectedAuthoringScopeProvider.overrideWith(
      (ref) =>
          scope ??
          AuthoringScope(
            organizationId:
                ref.watch(organizationIdProvider) ??
                skir.recordId("organization:fixture"),
            realmId:
                ref.watch(realmIdProvider) ?? skir.recordId("realm:fixture"),
          ),
    ),
    confirmedAuthoringDocumentProvider.overrideWith((ref, scope) {
      scripted.addListener(ref.invalidateSelf);
      ref.onDispose(() => scripted.removeListener(ref.invalidateSelf));
      return scripted.observation;
    }),
    localWorkScopeProvider.overrideWith((ref) {
      final selected = ref.watch(selectedAuthoringScopeProvider);
      return LocalWorkScope(
        userId: "fixture",
        organizationId: selected?.organizationId,
      );
    }),
    realmEditPersistenceProvider.overrideWith(
      (ref, scope) => scripted.persistence,
    ),
    authoredResourceCommandsProvider.overrideWith(
      (ref, scope) =>
          commandsFactory?.call(ref, scripted) ??
          commands ??
          fixtureAuthoringCommands(scripted),
    ),
  ];
}

AuthoredResourceCommands fixtureAuthoringCommands(
  ScriptedAuthoringTransport transport, {
  Future<skir.PreparationStep> Function(skir.PreparationOperation)? prepareStep,
  Future<skir.ResolveResourceOperationsResult> Function(
    skir.ResolveResourceOperationsRequest,
  )?
  resolveResourceOperations,
  Future<skir.AuthoringActionResult> Function(
    skir.PrepareAuthoringActionRequest,
  )?
  prepareAuthoringAction,
}) => AuthoredResourceCommands(
  previewTypeArguments: ({required resource, required requested}) async =>
      throw StateError("No type preview reply was scripted"),
  prepareTypeArguments: (_) async =>
      throw StateError("No type preparation reply was scripted"),
  prepareValue: (request) async => _fixturePrepareValue(transport, request),
  prepareStep:
      prepareStep ??
      (operation) async =>
          fixturePreparationStep(transport.observation.requireValue, operation),
  invokeCommand: ({required capabilityId, required payload}) async =>
      throw StateError("No command reply was scripted"),
  search: (_) async =>
      throw StateError("No resource search reply was scripted"),
  watchSearch: (_) => Stream.error(StateError("No search reply was scripted")),
  reload: () async {},
  resolveResourceOperations:
      resolveResourceOperations ??
      (_) async => skir.ResolveResourceOperationsResult.wrapResolved(
        skir.ResolvedResourceOperations(
          operations: const [],
          primaryOperation: null,
        ),
      ),
  prepareAuthoringAction:
      prepareAuthoringAction ??
      (_) async =>
          throw StateError("No authoring preparation reply was scripted"),
);

skir.PreparedValue _fixturePrepareValue(
  ScriptedAuthoringTransport transport,
  skir.ValuePreparationRequest request,
) {
  final catalog = transport.observation.requireValue.catalog;
  if (catalog.snapshot.generation != request.catalog) {
    throw StateError("The fixture catalog changed");
  }
  final defaults = transport.observation.requireValue;
  if (request.target case skir.PreparationTarget_valueWrapper(:final value)) {
    final named = catalog.namedUse(value);
    final prepared = named == null
        ? defaults.defaultValue(value)
        : skir.DataValue.createNamed(
            actualType: named,
            payload: skir.DataValue.createRecord(
              fields: [
                for (final field in catalog.fields(
                  skir.TypeSelection.wrapComplete(named),
                ))
                  skir.FieldValue(
                    name: field.template.key,
                    value: defaults.defaultValue(field.type),
                  ),
              ],
            ),
          );
    return skir.PreparedValue(
      content: skir.PreparedContent.wrapValue(
        request.suppliedValue ?? prepared,
      ),
      findings: const [],
    );
  }

  return skir.PreparedValue(
    content: skir.PreparedContent.wrapRecord(
      skir.AuthoringRecord(
        configuration: request.recordSelection,
        fields: [
          for (final field in catalog.fields(request.recordSelection))
            skir.FieldValue(
              name: field.template.key,
              value:
                  request.recordSuppliedFields
                      .firstWhereOrNull(
                        (value) => value.name == field.template.key,
                      )
                      ?.value ??
                  defaults.defaultValue(field.type),
            ),
        ],
      ),
    ),
    findings: const [],
  );
}

/// Portable fixture initialization. Native constructor captures belong to Realm tests.
skir.PreparationStep fixturePreparationStep(
  AuthoringDocument document,
  skir.PreparationOperation operation,
) {
  late skir.PreparationTarget target;
  late skir.AuthoringRecord record;
  switch (operation) {
    case skir.PreparationOperation_startWrapper(:final value):
      if (value.catalog != document.generation) {
        throw StateError("The fixture catalog changed");
      }
      target = value.target;
      record = skir.AuthoringRecord(
        configuration: value.recordSelection,
        fields: [
          for (final field in document.catalog.fields(value.recordSelection))
            skir.FieldValue(
              name: field.template.key,
              value:
                  value.recordSuppliedFields
                      .firstWhereOrNull(
                        (input) => input.name == field.template.key,
                      )
                      ?.value ??
                  document.defaultValue(field.type),
            ),
        ],
      );
    case skir.PreparationOperation_resumeWrapper(:final value):
      if (value.draft.catalog != document.generation) {
        throw StateError("The fixture catalog changed");
      }
      target = value.draft.target;
      record = switch (value.draft.content) {
        skir.PreparedContent_recordWrapper(:final value) => value,
        _ => throw StateError("Fixture preparation requires record content"),
      };
      for (final answer in value.answers) {
        record = switch (record.replaceAt(answer.path, answer.value)) {
          PortablePathValue(:final value) => value,
          PortablePathUnavailable(:final message) => throw StateError(message),
        };
      }
    case skir.PreparationOperation_unknown():
      throw StateError("Unknown fixture preparation operation");
  }
  final required = <skir.RequiredInput>[];
  void visit(skir.DataValue value, skir.ValuePath path) {
    if (value.authoredPayload == skir.DataValue.unfilled) {
      final expected = document.catalog.valueTypeAt(record.configuration, path);
      if (expected != null) {
        required.add(skir.RequiredInput(path: path, expected: expected));
      }
      return;
    }
    for (final field
        in value.authoredRecord?.fields ?? const <skir.FieldValue>[]) {
      visit(
        field.value,
        skir.ValuePath(
          segments: [
            ...path.segments,
            skir.PathSegment.createField(name: field.name),
          ],
        ),
      );
    }
    for (final item in value.authoredItems ?? const <skir.ListItem>[]) {
      visit(
        item.value,
        skir.ValuePath(
          segments: [
            ...path.segments,
            skir.PathSegment.createItem(id: item.id),
          ],
        ),
      );
    }
  }

  visit(
    skir.DataValue.createRecord(fields: record.fields),
    skir.ValuePath(segments: const []),
  );
  final content = skir.PreparedContent.wrapRecord(record);
  if (required.isEmpty) {
    return skir.PreparationStep.wrapReady(
      skir.PreparedValue(content: content, findings: const []),
    );
  }
  return skir.PreparationStep.wrapNeedsInput(
    skir.PreparationDraft(
      catalog: document.generation,
      target: target,
      content: content,
      pendingDefaults: const [],
      requiredInputs: required,
      findings: const [],
    ),
  );
}

AuthoringDocument fixtureAuthoringDocument({
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  Iterable<Page> pages = const [],
  CheckedEditorCatalog? catalog,
}) {
  final entries = <skir.ResourceId, skir.AuthoringResource>{};
  final projections = <skir.LinkProjection>[];
  skir.AuthoringResource record(
    skir.ResourceId id,
    String kind,
    Map<String, skir.DataValue> fields,
  ) => skir.AuthoringResource(
    id: id,
    definition: skir.ResourceDefinitionId(value: "typewriter.$kind"),
    content: skir.AuthoringRecord(
      configuration: _selection(kind),
      fields: [
        for (final entry in fields.entries) _field(entry.key, entry.value),
      ],
    ),
  );
  skir.DataValue links(
    skir.ResourceId source,
    String field,
    Iterable<skir.ResourceId> targets,
    String kind,
    String relation,
  ) {
    final items = <skir.ListItem>[];
    for (final (index, target) in targets.indexed) {
      final item = skir.ItemId(value: "fixture:${source.value}:$field:$index");
      final path = skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: field),
          skir.PathSegment.createItem(id: item),
        ],
      );
      final endpoint = skir.EndpointId(value: "$relation.first");
      items.add(
        skir.ListItem(
          id: item,
          value: _named(
            "${kind}Link",
            skir.DataValue.createLink(
              endpoint: endpoint,
              target: skir.LinkTarget(
                resource: target,
                opposite: kind == "bookPages"
                    ? skir.ValuePath(
                        segments: [skir.PathSegment.createField(name: "book")],
                      )
                    : null,
              ),
            ),
          ),
        ),
      );
      projections.add(
        skir.LinkProjection(
          contract: skir.RelationId(value: relation),
          first: source,
          second: target,
          firstLocation: path,
          secondLocation: kind == "bookPages"
              ? skir.ValuePath(
                  segments: [skir.PathSegment.createField(name: "book")],
                )
              : null,
        ),
      );
    }
    return _named(
      "${kind}Collection",
      skir.DataValue.createSetValue(items: items),
    );
  }

  final pageList = pages.toList();
  for (final tag in tags) {
    entries[tag.tagId] = record(tag.tagId, "tag", {
      "name": skir.DataValue.wrapStringValue(tag.name),
      "color": _integer(tag.color.toARGB32()),
      "parents": links(
        tag.tagId,
        "parents",
        tag.parentIds,
        "tagParents",
        "fixture.tag.parents",
      ),
      "placement": _named(
        "placement",
        skir.DataValue.createRecord(
          fields: [
            _field("x", _integer(tag.placement.x)),
            _field("y", _integer(tag.placement.y)),
            _field("width", _integer(tag.placement.width)),
            _field("height", _integer(tag.placement.height)),
          ],
        ),
      ),
    });
  }
  for (final book in books) {
    entries[book.bookId] = record(book.bookId, "book", {
      "title": skir.DataValue.wrapStringValue(book.title),
      "color": _integer(book.color.toARGB32()),
      "icon": _named(
        "icon",
        skir.DataValue.createRecord(
          fields: [_field("value", skir.DataValue.wrapStringValue(book.icon))],
        ),
      ),
      "tags": links(
        book.bookId,
        "tags",
        book.tagIds,
        "bookTags",
        "fixture.book.tags",
      ),
      "pages": links(
        book.bookId,
        "pages",
        pageList
            .where((page) => page.bookId == book.bookId)
            .map((page) => page.pageId),
        "bookPages",
        "fixture.book.pages",
      ),
    });
  }
  for (final page in pageList) {
    entries[page.pageId] = record(page.pageId, "page", {
      "name": skir.DataValue.wrapStringValue(page.name),
      "chapter": skir.DataValue.wrapStringValue(page.chapter),
      "priority": _integer(page.priority),
      "book": page.bookId == null
          ? skir.DataValue.unfilled
          : _named(
              "pageBookLink",
              skir.DataValue.createLink(
                endpoint: skir.EndpointId(value: "fixture.book.pages.second"),
                target: skir.LinkTarget(resource: page.bookId!, opposite: null),
              ),
            ),
    });
  }
  return AuthoringDocument(
    confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
    catalog: catalog ?? authoringFixtureCatalog(),
    entries: entries,
    links: projections,
  );
}

CheckedEditorCatalog authoringFixtureCatalog({
  skir.CatalogGeneration? generation,
}) {
  final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final integer = skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
  );
  final fields = <String, Map<String, skir.TypeTemplate>>{
    "tag": {
      "name": text,
      "color": integer,
      "parents": _template("tagParentsCollection"),
      "placement": _template("placement"),
    },
    "book": {
      "title": text,
      "color": integer,
      "icon": _template("icon"),
      "tags": _template("bookTagsCollection"),
      "pages": _template("bookPagesCollection"),
    },
    "page": {
      "name": text,
      "chapter": text,
      "priority": integer,
      "book": _template("pageBookLink"),
    },
    "placement": {
      "x": integer,
      "y": integer,
      "width": integer,
      "height": integer,
    },
    "icon": {"value": text},
  };
  final types = <skir.PublishedType>[
    for (final type in fields.entries)
      _published(
        type.key,
        skir.RepresentationTemplate.createRecord(
          abstract_: false,
          fields: [
            for (final field in type.value.entries)
              skir.FieldDeclaration(
                owner: skir.FieldOwner(
                  definition: _definition(type.key),
                  name: field.key,
                ),
                type: field.value,
                overrides: const [],
                hasConstructorDefault: false,
              ),
          ],
        ),
        fields: type.value,
      ),
  ];
  final relations = <skir.RelationContract>[];
  final bindings = <skir.EndpointBindingTemplate>[];
  for (final spec in [
    ("tagParents", "tag", "parents", "tag", "fixture.tag.parents"),
    ("bookTags", "book", "tags", "tag", "fixture.book.tags"),
    ("bookPages", "book", "pages", "page", "fixture.book.pages"),
  ]) {
    final (kind, source, field, target, relation) = spec;
    final endpoint = skir.EndpointId(value: "$relation.first");
    types.add(
      _published(
        "${kind}Link",
        skir.RepresentationTemplate.createLink(
          endpoint: endpoint,
          target: _template(target),
        ),
      ),
    );
    types.add(
      _published(
        "${kind}Collection",
        skir.RepresentationTemplate.createSequence(
          item: _template("${kind}Link"),
          kind: skir.CollectionKind.set_,
        ),
      ),
    );
    bindings.add(
      skir.EndpointBindingTemplate(
        endpoint: endpoint,
        containingResource: _namedTemplate(source),
        valueOwner: _definition(source),
        relativePath: skir.RelativeFieldPattern(
          segments: [
            skir.FieldPatternSegment.createField(name: field),
            skir.FieldPatternSegment.items,
          ],
        ),
        target: _template(target),
        containsCollection: true,
      ),
    );
    relations.add(
      skir.RelationContract(
        id: skir.RelationId(value: relation),
        first: skir.EndpointDefinition(
          id: endpoint,
          slot: skir.EndpointSlot.first,
          resource: _namedTemplate(source),
          cardinality: kind == "bookPages"
              ? skir.EndpointCardinality.one
              : skir.EndpointCardinality.many,
          onDelete: kind == "bookPages"
              ? skir.RelationDeletePolicy.cascade
              : skir.RelationDeletePolicy.clear,
        ),
        second: skir.EndpointDefinition(
          id: skir.EndpointId(value: "$relation.second"),
          slot: skir.EndpointSlot.second,
          resource: _namedTemplate(target),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: kind == "bookPages"
            ? [skir.RelationFamilyId(value: "resource.ownership")]
            : const [],
      ),
    );
  }
  types.add(
    _published(
      "pageBookLink",
      skir.RepresentationTemplate.createLink(
        endpoint: skir.EndpointId(value: "fixture.book.pages.second"),
        target: _template("book"),
      ),
    ),
  );
  bindings.add(
    skir.EndpointBindingTemplate(
      endpoint: skir.EndpointId(value: "fixture.book.pages.second"),
      containingResource: _namedTemplate("page"),
      valueOwner: _definition("page"),
      relativePath: skir.RelativeFieldPattern(
        segments: [skir.FieldPatternSegment.createField(name: "book")],
      ),
      target: _template("book"),
      containsCollection: false,
    ),
  );
  final descriptors = <skir.PresentationDescriptor>[];
  final materials = <skir.PresentationMaterial>[];
  for (final kind in ["tag", "book", "page"]) {
    final field = kind == "book" ? "title" : "name";
    final target = skir.PresentationTarget.createNamed(
      definition: _definition(kind),
      arguments: const [],
    );
    for (final role in [
      skir.PresentationRole.inspector,
      skir.PresentationRole.editor,
      skir.PresentationRole.graphNode,
      skir.PresentationRole.collectionItem,
    ]) {
      final id = skir.PresentationId(
        namespace: "fixture",
        name: "$kind.${role.kind.name}",
      );
      final reference = skir.BindingRef(
        bindingId: configuredValueBindingId,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: field)],
        ),
      );
      descriptors.add(
        skir.PresentationDescriptor(
          id: id,
          owner: skir.DeclarationOwner.defaultInstance,
          target: target,
          roles: [role],
          priority: 0,
        ),
      );
      materials.add(
        skir.PresentationMaterial(
          inheritableNodes: const [],
          resultAppearance: null,

          provider: id,
          target: target,
          role: role,
          subject: _template(kind),
          dependencies: skir.PresentationDependencies.defaultInstance,
          layout: skir.PresentationNode(
            nodeId: "fixture.$kind.$field",
            properties: skir.PresentationProperties.defaultInstance,
            header: null,
            element:
                role == skir.PresentationRole.inspector ||
                    role == skir.PresentationRole.editor
                ? skir.PresentationElement.createTextInput(
                    control: skir.BoundControl(
                      binding: reference,
                      label: skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapStringValue(field),
                      ),
                      description: null,
                      prefix: null,
                      semanticLabel: null,
                    ),
                    appearance: null,
                    content: null,
                    entry: null,
                    mappings: null,
                    options: skir.TextEditingOptions.defaultInstance,
                  )
                : skir.PresentationElement.wrapText(
                    (skir.TextContent.mutable()
                          ..value = skir.ExpressionNode.createInput(
                            binding: reference.bindingId,
                            path: reference.path,
                          ))
                        .toFrozen(),
                  ),
          ),
        ),
      );
    }
  }
  return CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      resourceOperations: const [],
      resourceOperationContributions: const [],
      generation:
          generation ??
          skir.CatalogGeneration(value: realmFixtureGeneration.value),
      types: types,
      relations: relations,
      resourceDefinitions: [
        for (final (kind, handler) in [
          ("tag", skir.AuthoringNavigationHandler.tags),
          ("book", skir.AuthoringNavigationHandler.book),
          ("page", skir.AuthoringNavigationHandler.page),
        ])
          skir.AuthoringResourceDefinition(
            id: skir.ResourceDefinitionId(value: "typewriter.$kind"),
            root: _definition(kind),
            navigationHandler: handler,
          ),
      ],
      presentations: descriptors,
      presentationMaterials: materials,
      configuration: const [],
      diagnostics: const [],

      endpointBindings: bindings,
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
}

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "fixture", name: name),
  revision: 1,
);
skir.NamedTypeUse _use(String name) =>
    skir.NamedTypeUse(definition: _definition(name), arguments: const []);
skir.TypeSelection _selection(String name) =>
    skir.TypeSelection.wrapComplete(_use(name));
skir.NamedTypeTemplate _namedTemplate(String name) =>
    skir.NamedTypeTemplate(definition: _definition(name), arguments: const []);
skir.TypeTemplate _template(String name) =>
    skir.TypeTemplate.wrapNamed(_namedTemplate(name));
skir.DataValue _named(String name, skir.DataValue payload) =>
    skir.DataValue.createNamed(actualType: _use(name), payload: payload);
skir.DataValue _integer(int value) =>
    skir.DataValue.wrapInteger(value.toString());
skir.FieldValue _field(String name, skir.DataValue value) =>
    skir.FieldValue(name: name, value: value);
skir.PublishedType _published(
  String name,
  skir.RepresentationTemplate representation, {
  Map<String, skir.TypeTemplate> fields = const {},
}) => skir.PublishedType(
  definition: skir.TypeDefinition(
    id: _definition(name),
    parameters: const [],
    representation: representation,
    parents: const [],
  ),
  display: null,
  status: skir.DeclarationStatus.ready,
  effectiveFields: [
    for (final field in fields.entries)
      skir.EffectiveFieldTemplate(
        key: field.key,
        owner: skir.FieldOwner(definition: _definition(name), name: field.key),
        type: field.value,
        rules: const [],
      ),
  ],
  ancestorTemplates: const [],
);

/// External reply control composed with the production editing owner.
RealmEditPersistence fixtureRealmPersistence({
  required Future<skir.CommitPreparedEditResponse> Function(skir.PreparedEdit)
  commit,
  required Future<AuthoringDocument> Function() confirmed,
}) => RealmEditPersistence(
  reservations: (edits) => {for (final edit in edits) ...edit.editedResources},
  observe: confirmed,
  request: (edit) => PreparedCommit(
    id: Object(),
    label: "Apply fixture changes",
    resources: edit.editedResources.toSet(),
    send: () async {
      final response = await commit(edit);
      return switch (response) {
        skir.CommitPreparedEditResponse_internalErrorWrapper() ||
        skir.CommitPreparedEditResponse_unknown() => SubmissionResult.uncertain(
          message: "Unknown fixture outcome",
          cause: response,
          stackTrace: StackTrace.current,
        ),
        skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult.committed,
        ) =>
          SubmissionResult.confirmed(response),
        _ => SubmissionResult.rejected(
          message: response.rejectionMessage,
          response: response,
        ),
      };
    },
  ),
);
