import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The realm root every seeded Realm document holds.
final realmRootId = skir.ResourceId(value: "library:realm");

/// The Library section, which owns every Book of a seeded Realm.
final libraryId = skir.ResourceId(value: "library:library");

/// The tags section, which owns every Tag of a seeded Realm.
final taxonomyId = skir.ResourceId(value: "library:taxonomy");

/// The saved document of a Realm holding [books], [tags], [pages] and
/// [scenes], as Realm provisions it: the realm root owns a Library and a tags
/// section, which own every Book and Tag; Books own their pages. Each scene is
/// one more section of the realm root, owning its tracks, which own their
/// cues.
///
/// The [realm] trait seeds the same document; tests of the authoring model
/// that need no panel start from it directly. [catalog] replaces the
/// [libraryCatalog] the resources are typed by.
AuthoringDocument realmDocument({
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  Iterable<Page> pages = const [],
  Iterable<Scene> scenes = const [],
  CheckedEditorCatalog? catalog,
}) {
  final entries = <skir.ResourceId, skir.AuthoringResource>{};
  final projections = <skir.LinkProjection>[];
  void record(
    skir.ResourceId id,
    String kind,
    Map<String, skir.DataValue> fields,
  ) => entries[id] = skir.AuthoringResource(
    id: id,
    content: skir.AuthoringRecord(
      configuration: _selection(kind),
      fields: [
        for (final entry in fields.entries) _field(entry.key, entry.value),
      ],
    ),
  );
  skir.ValuePath fieldPath(String field) =>
      skir.ValuePath(segments: [skir.PathSegment.createField(name: field)]);

  /// The owner's list of links to [targets] for [spec], projecting each link
  /// with the member's back reference when the relation declares one.
  skir.DataValue links(
    skir.ResourceId source,
    Iterable<skir.ResourceId> targets,
    _LibraryRelation spec,
  ) {
    final items = <skir.ListItem>[];
    for (final (index, target) in targets.indexed) {
      final item = skir.ItemId(
        value: "library:${source.value}:${spec.field}:$index",
      );
      final path = skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: spec.field),
          skir.PathSegment.createItem(id: item),
        ],
      );
      final opposite = spec.backReference == null
          ? null
          : fieldPath(spec.backReference!);
      items.add(
        skir.ListItem(
          id: item,
          value: _named(
            "${spec.kind}Link",
            skir.DataValue.createLink(
              endpoint: spec.first,
              target: skir.LinkTarget(resource: target, opposite: opposite),
            ),
          ),
        ),
      );
      projections.add(
        skir.LinkProjection(
          contract: spec.id,
          first: source,
          second: target,
          firstLocation: path,
          secondLocation: opposite,
        ),
      );
    }
    return _named(
      "${spec.kind}Collection",
      spec.list
          ? skir.DataValue.createListValue(items: items)
          : skir.DataValue.createSetValue(items: items),
    );
  }

  skir.DataValue backReference(skir.ResourceId? owner, _LibraryRelation spec) =>
      owner == null
      ? skir.DataValue.unfilled
      : _named(
          "${spec.kind}BackLink",
          skir.DataValue.createLink(
            endpoint: spec.second,
            target: skir.LinkTarget(resource: owner, opposite: null),
          ),
        );

  final pageList = pages.toList();
  final bookList = books.toList();
  final tagList = tags.toList();
  final sceneList = scenes.toList();
  {
    record(realmRootId, "realm", {
      "sections": links(realmRootId, [
        libraryId,
        taxonomyId,
        for (final scene in sceneList) scene.sceneId,
      ], _realmSections),
    });
    record(libraryId, "library", {
      "books": links(
        libraryId,
        bookList.map((book) => book.bookId),
        _libraryBooks,
      ),
    });
    record(taxonomyId, "taxonomy", {
      "tags": links(taxonomyId, tagList.map((tag) => tag.tagId), _taxonomyTags),
    });
  }
  for (final tag in tagList) {
    record(tag.tagId, "tag", {
      "name": skir.DataValue.wrapStringValue(tag.name),
      "color": _integer(tag.color.toARGB32()),
      "parents": links(tag.tagId, tag.parentIds, _tagParents),
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
      "taxonomy": backReference(taxonomyId, _taxonomyTags),
    });
  }
  for (final book in bookList) {
    record(book.bookId, "book", {
      "title": skir.DataValue.wrapStringValue(book.title),
      "color": _integer(book.color.toARGB32()),
      "icon": _named(
        "icon",
        skir.DataValue.createRecord(
          fields: [_field("value", skir.DataValue.wrapStringValue(book.icon))],
        ),
      ),
      "tags": links(book.bookId, book.tagIds, _bookTags),
      "pages": links(
        book.bookId,
        pageList
            .where((page) => page.bookId == book.bookId)
            .map((page) => page.pageId),
        _bookPages,
      ),
      "library": backReference(libraryId, _libraryBooks),
    });
  }
  for (final page in pageList) {
    record(page.pageId, "page", {
      "name": skir.DataValue.wrapStringValue(page.name),
      "chapter": skir.DataValue.wrapStringValue(page.chapter),
      "priority": _integer(page.priority),
      "book": backReference(page.bookId, _bookPages),
    });
  }
  for (final scene in sceneList) {
    record(scene.sceneId, "scene", {
      "name": skir.DataValue.wrapStringValue(scene.name),
      "tracks": links(
        scene.sceneId,
        scene.tracks.map((track) => track.trackId),
        _sceneTracks,
      ),
    });
    for (final track in scene.tracks) {
      record(track.trackId, "track", {
        "name": skir.DataValue.wrapStringValue(track.name),
        "cues": links(
          track.trackId,
          track.cues.map((cue) => cue.cueId),
          _trackCues,
        ),
        "scene": backReference(scene.sceneId, _sceneTracks),
      });
      for (final cue in track.cues) {
        record(cue.cueId, "cue", {
          "name": skir.DataValue.wrapStringValue(cue.name),
          "placement": TimelineSegmentPlacement(
            startFrame: cue.startFrame,
            endFrame: cue.endFrame,
          ).toAuthoredValue(),
          "track": backReference(track.trackId, _trackCues),
        });
      }
    }
  }
  return AuthoringDocument(
    confirmedObservation: skir.AuthoringObservationId(value: "library:saved"),
    catalog: catalog ?? libraryCatalog(),
    entries: entries,
    links: projections,
  );
}

/// One relation of the library catalog: the [field] of the first endpoint's
/// resource lists links to the second's, which optionally link back through
/// [backReference].
final class _LibraryRelation {
  const _LibraryRelation({
    required this.kind,
    required this.relation,
    required this.owner,
    required this.field,
    required this.member,
    this.backReference,
    this.ownership = false,
    this.list = true,
  });

  final String kind;
  final String relation;
  final String owner;
  final String field;
  final String member;
  final String? backReference;
  final bool ownership;
  final bool list;

  skir.RelationId get id => skir.RelationId(value: relation);
  skir.EndpointId get first => skir.EndpointId(value: "$relation:first");
  skir.EndpointId get second => skir.EndpointId(value: "$relation:second");
}

const _realmSections = _LibraryRelation(
  kind: "realmSections",
  relation: "library.realm.sections",
  owner: "realm",
  field: "sections",
  member: "section",
  ownership: true,
);
const _libraryBooks = _LibraryRelation(
  kind: "libraryBooks",
  relation: "library.library.books",
  owner: "library",
  field: "books",
  member: "book",
  backReference: "library",
  ownership: true,
);
const _taxonomyTags = _LibraryRelation(
  kind: "taxonomyTags",
  relation: "library.taxonomy.tags",
  owner: "taxonomy",
  field: "tags",
  member: "tag",
  backReference: "taxonomy",
  ownership: true,
);
const _tagParents = _LibraryRelation(
  kind: "tagParents",
  relation: "library.tag.parents",
  owner: "tag",
  field: "parents",
  member: "tag",
  list: false,
);
const _bookTags = _LibraryRelation(
  kind: "bookTags",
  relation: "library.book.tags",
  owner: "book",
  field: "tags",
  member: "tag",
  list: false,
);

/// The relation by which Books own their pages.
const bookPagesRelation = "library.book.pages";

const _bookPages = _LibraryRelation(
  kind: "bookPages",
  relation: bookPagesRelation,
  owner: "book",
  field: "pages",
  member: "page",
  backReference: "book",
  ownership: true,
);
const _sceneTracks = _LibraryRelation(
  kind: "sceneTracks",
  relation: "library.scene.tracks",
  owner: "scene",
  field: "tracks",
  member: "track",
  backReference: "scene",
  ownership: true,
);
const _trackCues = _LibraryRelation(
  kind: "trackCues",
  relation: "library.track.cues",
  owner: "track",
  field: "cues",
  member: "cue",
  backReference: "track",
  ownership: true,
);
const _libraryRelations = [
  _realmSections,
  _libraryBooks,
  _taxonomyTags,
  _tagParents,
  _bookTags,
  _bookPages,
  _sceneTracks,
  _trackCues,
];

/// The type of resource [kind] (realm, library, taxonomy, book, tag, page,
/// scene, track or cue)
/// in the [libraryCatalog].
skir.TypeDefinitionId libraryType(String kind) => _definition(kind);

/// A catalog standing in for Realm's library: a realm root owning a Library
/// and a tags section, Books owning pages, and Tags with parents. Pages have a
/// workspace and Books a chapter tree navigator, so surfaces resolve as they
/// do against Realm. [bookIcon] adds the icon name as a second field below
/// a Book's title in its inspector.
CheckedEditorCatalog libraryCatalog({
  skir.CatalogGeneration? generation,
  bool bookIcon = false,
}) {
  final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final integer = skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
  );
  final fields = <String, Map<String, skir.TypeTemplate>>{
    "realm": {"sections": _template("realmSectionsCollection")},
    "library": {"books": _template("libraryBooksCollection")},
    "taxonomy": {"tags": _template("taxonomyTagsCollection")},
    "tag": {
      "name": text,
      "color": integer,
      "parents": _template("tagParentsCollection"),
      "placement": _template("placement"),
      "taxonomy": _template("taxonomyTagsBackLink"),
    },
    "book": {
      "title": text,
      "color": integer,
      "icon": _template("icon"),
      "tags": _template("bookTagsCollection"),
      "pages": _template("bookPagesCollection"),
      "library": _template("libraryBooksBackLink"),
    },
    "page": {
      "name": text,
      "chapter": text,
      "priority": integer,
      "book": _template("bookPagesBackLink"),
    },
    "scene": {"name": text, "tracks": _template("sceneTracksCollection")},
    "track": {
      "name": text,
      "cues": _template("trackCuesCollection"),
      "scene": _template("sceneTracksBackLink"),
    },
    "cue": {
      "name": text,
      "placement": _template("segment"),
      "track": _template("trackCuesBackLink"),
    },
    "segment": {"startFrame": integer, "endFrame": integer},
    "placement": {
      "x": integer,
      "y": integer,
      "width": integer,
      "height": integer,
    },
    "icon": {"value": text},
    "hierarchyGroup": {
      "path": text,
      "name": text,
      "members": skir.TypeTemplate.createNamed(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "typewriter",
            name: "List",
          ),
          revision: 1,
        ),
        arguments: [
          skir.TypeTemplate.createNamed(
            definition: skir.resourceIdType.definition,
            arguments: const [],
          ),
        ],
      ),
    },
  };
  const sectionKinds = {"library", "taxonomy", "scene"};
  // Resource types publish a search key, as the Kotlin catalog does.
  const resourceKinds = {
    "realm",
    ...sectionKinds,
    "tag",
    "book",
    "page",
    "track",
    "cue",
  };
  final types = <skir.PublishedType>[
    _published(
      "section",
      skir.RepresentationTemplate.createRecord(abstract_: true, fields: []),
    ),
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
        ancestors: sectionKinds.contains(type.key) ? ["section"] : const [],
        searchKey: resourceKinds.contains(type.key) ? type.key : null,
        display: _sectionDisplays[type.key],
      ),
  ];
  final relations = <skir.RelationContract>[];
  final bindings = <skir.EndpointBindingTemplate>[];
  for (final spec in _libraryRelations) {
    types.add(
      _published(
        "${spec.kind}Link",
        skir.RepresentationTemplate.createLink(
          endpoint: spec.first,
          target: _template(spec.member),
        ),
      ),
    );
    types.add(
      _published(
        "${spec.kind}Collection",
        skir.RepresentationTemplate.createSequence(
          item: _template("${spec.kind}Link"),
          kind: spec.list ? skir.CollectionKind.list : skir.CollectionKind.set_,
        ),
      ),
    );
    bindings.add(
      skir.EndpointBindingTemplate(
        endpoint: spec.first,
        containingResource: _namedTemplate(spec.owner),
        valueOwner: _definition(spec.owner),
        relativePath: skir.RelativeFieldPattern(
          segments: [
            skir.FieldPatternSegment.createField(name: spec.field),
            skir.FieldPatternSegment.items,
          ],
        ),
        target: _template(spec.member),
        containsCollection: true,
      ),
    );
    if (spec.backReference case final field?) {
      types.add(
        _published(
          "${spec.kind}BackLink",
          skir.RepresentationTemplate.createLink(
            endpoint: spec.second,
            target: _template(spec.owner),
          ),
        ),
      );
      bindings.add(
        skir.EndpointBindingTemplate(
          endpoint: spec.second,
          containingResource: _namedTemplate(spec.member),
          valueOwner: _definition(spec.member),
          relativePath: skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: field)],
          ),
          target: _template(spec.owner),
          containsCollection: false,
        ),
      );
    }
    relations.add(
      skir.RelationContract(
        id: spec.id,
        first: skir.EndpointDefinition(
          id: spec.first,
          slot: skir.EndpointSlot.first,
          resource: _namedTemplate(spec.owner),
          cardinality: spec.ownership
              ? skir.EndpointCardinality.one
              : skir.EndpointCardinality.many,
          onDelete: spec.ownership
              ? skir.RelationDeletePolicy.cascade
              : skir.RelationDeletePolicy.clear,
        ),
        second: skir.EndpointDefinition(
          id: spec.second,
          slot: skir.EndpointSlot.second,
          resource: _namedTemplate(spec.member),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: spec.ownership ? [skir.resourceOwnershipFamily] : const [],
      ),
    );
  }
  final descriptors = <skir.PresentationDescriptor>[];
  final materials = <skir.PresentationMaterial>[];
  void present(
    String kind,
    skir.PresentationRole role,
    skir.PresentationNode layout,
  ) {
    final target = skir.PresentationTarget.createNamed(
      definition: _definition(kind),
      arguments: const [],
    );
    final id = skir.PresentationId(
      namespace: "library",
      name: "$kind.${role.kind.name}",
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
        provider: id,
        target: target,
        role: role,
        subject: _template(kind),
        dependencies: skir.PresentationDependencies.defaultInstance,
        layout: layout,
      ),
    );
  }

  skir.BindingRef field(String name) => skir.BindingRef(
    bindingId: configuredValueBindingId,
    path: skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]),
  );
  for (final kind in ["tag", "book", "page", "scene", "track", "cue"]) {
    final reference = field(kind == "book" ? "title" : "name");
    final input = skir.PresentationNode(
      nodeId: "library.$kind.${reference.path.segments.single}",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: textInputElement(
        reference,
        label: kind == "book" ? "title" : "name",
      ),
    );
    final label = skir.PresentationNode(
      nodeId: "library.$kind.label",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.wrapText(
        (skir.TextContent.mutable()
              ..value = skir.ExpressionNode.createInput(
                binding: reference.bindingId,
                path: reference.path,
              ))
            .toFrozen(),
      ),
    );
    present(
      kind,
      skir.PresentationRole.inspector,
      kind == "book" && bookIcon ? _withIconField(input) : input,
    );
    present(kind, skir.PresentationRole.referencePreview, label);
    if (kind == "page") present(kind, skir.PresentationRole.workspace, input);
    if (kind == "tag") present(kind, skir.PresentationRole.item, label);
  }
  // [relation] names the link collection the field holds; members are its links.
  skir.PresentationNode resources(
    String id,
    String linkField,
    String relation,
    skir.ResourcesLayout layout, {
    skir.ExpressionNode? order,
  }) => skir.PresentationNode(
    nodeId: id,
    properties: skir.PresentationProperties.defaultInstance,
    header: null,
    element: skir.PresentationElement.createResources(
      control: skir.BoundControl(
        binding: field(linkField),
        label: null,
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      layout: layout,
      order: order,
      itemBinding: skir.BindingDeclaration(
        id: libraryItemBinding,
        type: _template("${relation}Link"),
      ),
    ),
  );
  present(
    "realm",
    skir.PresentationRole.navigator,
    resources(
      "library.realm.sections",
      "sections",
      "realmSections",
      skir.ResourcesLayout.list,
    ),
  );
  present(
    "scene",
    skir.PresentationRole.workspace,
    resources(
      "library.scene.tracks",
      "tracks",
      "sceneTracks",
      skir.ResourcesLayout.createTimeline(appearance: null),
    ),
  );
  present(
    "library",
    skir.PresentationRole.workspace,
    resources(
      "library.library.books",
      "books",
      "libraryBooks",
      skir.ResourcesLayout.createGrid(
        itemExtent: _number(240),
        aspectRatio: _number(0.72),
        spacing: _number(16),
      ),
    ),
  );
  present(
    "taxonomy",
    skir.PresentationRole.workspace,
    resources(
      "library.taxonomy.tags",
      "tags",
      "taxonomyTags",
      skir.ResourcesLayout.createGraph(
        direction: skir.GraphDirection.topToBottom,
        appearance: null,
      ),
    ),
  );
  final group = skir.ExpressionBindingId(value: "library.book.chapter");
  present(
    "book",
    skir.PresentationRole.navigator,
    resources(
      "library.book.pages",
      "pages",
      "bookPages",
      order: portableCall("link.target", [
        skir.ExpressionNode.createInput(
          binding: libraryItemBinding,
          path: editorRootPath,
        ),
      ]),
      skir.ResourcesLayout.createTree(
        path: editorRootPath.field("chapter"),
        groupBinding: skir.BindingDeclaration(
          id: group,
          type: skir.TypeTemplate.createNamed(
            definition: hierarchyGroupUse.definition,
            arguments: const [],
          ),
        ),
        connectors: null,
        initiallyExpanded: true,
        group: skir.PresentationNode(
          nodeId: "library.book.chapter",
          properties: skir.PresentationProperties.defaultInstance,
          header: null,
          element: skir.PresentationElement.wrapChildren(
            skir.ChildrenElement.createWrap(
              children: [
                skir.PresentationNode(
                  nodeId: "library.book.chapter.name",
                  properties: skir.PresentationProperties.defaultInstance,
                  header: null,
                  element: skir.PresentationElement.wrapText(
                    (skir.TextContent.mutable()
                          ..value = skir.ExpressionNode.createInput(
                            binding: group,
                            path: editorRootPath.field("name"),
                          ))
                        .toFrozen(),
                  ),
                ),
                skir.PresentationNode(
                  nodeId: "library.book.chapter.create",
                  properties: skir.PresentationProperties.defaultInstance,
                  header: null,
                  element: skir.PresentationElement.createButton(
                    label: _literal("New page"),
                    action: skir.EditorAction.createCreate(
                      type: _definition("page"),
                      owner: field("pages"),
                      fields: [
                        skir.CreateFieldValue(
                          path: editorRootPath.field("chapter"),
                          value: skir.ExpressionNode.createInput(
                            binding: group,
                            path: editorRootPath.field("path"),
                          ),
                        ),
                      ],
                    ),
                    appearance: null,
                    icon: null,
                  ),
                ),
              ],
              layout: skir.WrapChildrenLayout.defaultInstance,
            ),
          ),
        ),
      ),
    ),
  );
  return CheckedEditorCatalog(
    testCatalogSnapshot(
      resourceDisplays: _libraryDisplays,
      generation:
          generation ??
          skir.CatalogGeneration(value: realmFixtureGeneration.value),
      types: types,
      relations: relations,
      realmRoot: _definition("realm"),
      presentations: descriptors,
      presentationMaterials: materials,
      endpointBindings: bindings,
    ),
  );
}

/// The item binding of every resources layout of the [libraryCatalog].
final libraryItemBinding = skir.ExpressionBindingId(
  value: "library.resources.item",
);

skir.ExpressionNode _literal(String value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));
skir.ExpressionNode _number(double value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(value));

/// The displays Realm publishes for the framework Book, Tag and Page and for
/// any resource, retargeted to the library types standing in for them, so
/// library resources are named exactly as Realm names them.
final _libraryDisplays = [
  for (final display in compiledSdkControlCatalog.resourceDisplays)
    if (display.target == skir.ResourceTarget.anyResource)
      display
    else
      for (final name
          in _displayStandIns[_displayTarget(display)] ?? const <String>[])
        skir.ResourceDisplayFormulas(
          target: skir.ResourceTarget.wrapType(_template(name)),
          label: display.label,
          accent: display.accent,
          icon: display.icon,
        ),
];

final _displayStandIns = {
  skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "bbb646b300cf4dd2b7aab051854e4dd1",
    ),
    revision: 1,
  ): [
    "book",
  ],
  skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "ce1ae253a42d4509935c48b8ecba664a",
    ),
    revision: 1,
  ): [
    "tag",
  ],
  skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "kotlin",
      name: "com.typewritermc.library.Page",
    ),
    revision: 1,
    // Scenes, tracks and cues are named by their name field, as pages are.
  ): [
    "page",
    "scene",
    "track",
    "cue",
  ],
};

skir.TypeDefinitionId? _displayTarget(skir.ResourceDisplayFormulas display) =>
    switch (display.target) {
      skir.ResourceTarget_typeWrapper(
        value: skir.TypeTemplate_namedWrapper(:final value),
      ) =>
        value.definition,
      _ => null,
    };

/// Library types standing in for framework types keep the framework identity,
/// so production readers such as graph placement recognize their values.
final _frameworkDefinitions = {
  "placement": graphPlacementTypeRef,
  "segment": timelineSegmentPlacementTypeRef,
  "hierarchyGroup": hierarchyGroupUse.definition,
};

/// The displays the Kotlin library model declares for the realm sections.
final _sectionDisplays = {
  "library": skir.TypeDisplay(
    name: "Library",
    description: "Every book of the realm",
    icon: skir.Icon.wrapIconify("material-symbols:local-library"),
    color: skir.Color(argb: 0xFF3F51B5),
  ),
  "taxonomy": skir.TypeDisplay(
    name: "Tags",
    description: "Every tag of the realm",
    icon: skir.Icon.wrapIconify("material-symbols:label"),
    color: skir.Color(argb: 0xFF795548),
  ),
};

skir.TypeDefinitionId _definition(String name) =>
    _frameworkDefinitions[name] ??
    skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(namespace: "library", name: name),
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
  List<String> ancestors = const [],
  String? searchKey,
  skir.TypeDisplay? display,
}) => publishedType(
  _definition(name),
  representation: representation,
  display: display,
  parents: [for (final ancestor in ancestors) _namedTemplate(ancestor)],
  ancestors: [for (final ancestor in ancestors) _namedTemplate(ancestor)],
  fields: [
    for (final field in fields.entries)
      skir.EffectiveFieldTemplate(
        key: field.key,
        owner: skir.FieldOwner(definition: _definition(name), name: field.key),
        type: field.value,
        rules: const [],
      ),
  ],
  searchKey: searchKey,
  placementField: fields.containsKey("placement")
      ? editorRootPath.field("placement")
      : null,
);

/// The saved document of a Realm whose [book] owns the page `page:[id]`,
/// which owns the element `element:[id]` and the cue `cue:[id]`, beside the
/// tag `tag:[id]`: owner chains of every depth below the realm root.
///
/// Elements and cues reuse the tag record, a type with no surface of its
/// own.
AuthoringDocument ownerChainDocument(Book book, {required String id}) {
  final page = Page(
    pageId: skir.ResourceId(value: "page:$id"),
    bookId: book.bookId,
    name: "Page",
  );
  final tag = Tag(
    tagId: skir.ResourceId(value: "tag:$id"),
    name: "Tag",
    color: Colors.blue,
  );
  final document = realmDocument(books: [book], pages: [page], tags: [tag]);
  final catalog = document.catalog.snapshot.toMutable();
  final relations = document.catalog.snapshot.relations.toList();
  final entries = {...document.entries};
  final links = [...document.links];
  final itemEntry = document.entry(tag.tagId)!;
  final owner = document.catalog.snapshot.relations.singleWhere(
    (relation) => relation.id.value == bookPagesRelation,
  );
  for (final kind in ["element", "cue"]) {
    final item = skir.ResourceId(value: "$kind:$id");
    final relation = skir.RelationId(value: "fixture.page.$kind");
    relations.add(
      testOwnershipRelation(
        relation.value,
        owner: owner.second.resource.definition,
        member: owner.second.resource.definition,
      ),
    );
    entries[item] = skir.AuthoringResource(
      id: item,
      content: itemEntry.content,
    );
    links.add(
      skir.LinkProjection(
        contract: relation,
        first: page.pageId,
        second: item,
        firstLocation: editorRootPath.field(kind),
        secondLocation: null,
      ),
    );
  }
  catalog.relations = relations;
  return document.copyWith(
    catalog: CheckedEditorCatalog(catalog.toFrozen()),
    entries: entries,
    links: links,
  );
}

/// [title] above a text input for the Book's icon name.
skir.PresentationNode _withIconField(skir.PresentationNode title) =>
    skir.PresentationNode(
      nodeId: "library.book.fields",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.wrapChildren(
        skir.ChildrenElement.createColumn(
          children: [
            skir.AxisChild.wrapFixed(title),
            skir.AxisChild.wrapFixed(
              skir.PresentationNode(
                nodeId: "library.book.icon",
                properties: skir.PresentationProperties.defaultInstance,
                header: null,
                element: textInputElement(
                  skir.BindingRef(
                    bindingId: configuredValueBindingId,
                    path: skir.ValuePath(
                      segments: [
                        skir.PathSegment.createField(name: "icon"),
                        skir.PathSegment.createField(name: "value"),
                      ],
                    ),
                  ),
                  label: "icon",
                ),
              ),
            ),
          ],
          layout: skir.AxisChildrenLayout(
            clipOverflow: false,
            spacing: 0,
            mainAxisAlignment: skir.MainAxisAlignment.start,
            crossAxisAlignment: skir.CrossAxisAlignment.start,
          ),
        ),
      ),
    );
