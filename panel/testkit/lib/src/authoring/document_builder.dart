/// One way to write the authored content a test starts from: a catalog of
/// types named by their test names, resources of readable values, and a
/// document that hands out the saved [skir.AuthoringState], the
/// [AuthoringDocument] the panel reads and a fresh [AuthoringEdit], and
/// names its values by location.
///
/// ```dart
/// final saved = authoredDoc(
///   [
///     authoredRecord("resource:1", {
///       "title": textValue("original"),
///     }, type: typeUse("Quest")),
///   ],
///   catalog: authoredCatalog([
///     declaredRecord("Step", open: true),
///     declaredRecord("Quest", fields: {"title": skir.ScalarKind.text}),
///   ]),
/// );
/// final edit = saved.edit;
/// final title = valueAt("resource:1", ["title"]);
/// ```
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/application/catalog_fixtures.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";
import "package:typewriter_testkit/src/shared/portable/values.dart";

/// The use of the test type [name] without type arguments.
skir.NamedTypeUse typeUse(String name) =>
    skir.NamedTypeUse(definition: testTypeId(name), arguments: const []);

/// [type] as a template: a [String] names a test type and a
/// [skir.TypeDefinitionId] a type, both without arguments; a
/// [skir.ScalarKind] is that scalar, and a [skir.TypeTemplate] or a
/// [skir.NamedTypeTemplate] stays itself.
skir.TypeTemplate typeTemplateOf(Object type) => switch (type) {
  final skir.ScalarKind scalar => skir.TypeTemplate.wrapScalar(scalar),
  final skir.TypeTemplate template => template,
  _ => skir.TypeTemplate.wrapNamed(_named(type)),
};

/// The type [type] names: a test type by its [String] name, or the
/// [skir.TypeDefinitionId] itself.
skir.TypeDefinitionId _id(Object type) => switch (type) {
  final String name => testTypeId(name),
  final skir.TypeDefinitionId id => id,
  _ => throw ArgumentError.value(type, "type", "names no type"),
};

skir.NamedTypeTemplate _named(Object type) => switch (type) {
  final skir.NamedTypeTemplate template => template,
  _ => skir.NamedTypeTemplate(definition: _id(type), arguments: const []),
};

/// [payload] held as the test type [type].
skir.DataValue typedValue(String type, skir.DataValue payload) =>
    skir.DataValue.createNamed(actualType: typeUse(type), payload: payload);

/// The display of a type shown as [name] with [description], [icon] and the
/// color [argb]; the icon and color default to the framework defaults.
skir.TypeDisplay typeDisplay(
  String name, {
  String description = "",
  String? icon,
  int? argb,
}) {
  final fallback = defaultTypeDisplay(name);
  return skir.TypeDisplay(
    name: name,
    description: description,
    icon: icon == null ? fallback.icon : skir.Icon.wrapIconify(icon),
    color: argb == null ? fallback.color : skir.Color(argb: argb.toSigned(32)),
  );
}

/// The record type [type], a test type name or a [skir.TypeDefinitionId],
/// declaring [fields], each a type as [typeTemplateOf] reads it: those in
/// [defaulted] have a constructor default and each checks the [rules]
/// listed under its name. With [inheritedFrom] the fields are not its own
/// but those it inherits from that type.
///
/// It refines [parents], whose fields [authoredCatalog] adds to its own; it
/// is concrete unless [open], or closed over [cases] when given; its [parameters] are bounded by the types
/// listed under each name. It is ready unless [status] says otherwise,
/// places by [placementField] when given and shows [display], the default
/// display unless given.
skir.PublishedType declaredRecord(
  Object type, {
  Map<String, Object> fields = const {},
  Set<String> defaulted = const {},
  Map<String, List<skir.RuleId>> rules = const {},
  Object? inheritedFrom,
  bool open = false,
  List<Object>? cases,
  List<Object> parents = const [],
  Map<String, List<Object>> parameters = const {},
  skir.DeclarationStatus status = skir.DeclarationStatus.ready,
  skir.ValuePath? placementField,
  skir.TypeDisplay? display,
  String? searchKey,
}) {
  final id = _id(type);
  final declarer = inheritedFrom == null ? id : _id(inheritedFrom);
  skir.FieldOwner owner(String field) =>
      skir.FieldOwner(definition: declarer, name: field);
  return publishedType(
    id,
    representation: skir.RepresentationTemplate.createRecord(
      fields: [
        if (inheritedFrom == null)
          for (final MapEntry(key: field, value: type) in fields.entries)
            skir.FieldDeclaration(
              owner: owner(field),
              type: typeTemplateOf(type),
              overrides: const [],
              hasConstructorDefault: defaulted.contains(field),
            ),
      ],
      form: cases != null
          ? skir.RecordForm.createClosed(
              cases: [for (final case_ in cases) _named(case_)],
            )
          : open
          ? skir.RecordForm.open
          : skir.RecordForm.concrete,
    ),
    parameters: [
      for (final (index, MapEntry(key: parameter, value: bounds))
          in parameters.entries.indexed)
        skir.TypeParameter(
          key: skir.ParameterKey(owner: id, index: index),
          name: parameter,
          bounds: [for (final bound in bounds) typeTemplateOf(bound)],
        ),
    ],
    parents: [for (final parent in parents) _named(parent)],
    fields: [
      for (final MapEntry(key: field, value: type) in fields.entries)
        skir.EffectiveFieldTemplate(
          key: field,
          owner: owner(field),
          type: typeTemplateOf(type),
          rules: rules[field] ?? const [],
        ),
    ],
    status: status,
    placementField: placementField,
    display: display,
    searchKey: searchKey,
  );
}

/// The enum [type], a test type name or a [skir.TypeDefinitionId]: a closed
/// record over the unit [cases], followed by one declaration per case.
List<skir.PublishedType> declaredEnum(Object type, List<String> cases) {
  final id = _id(type);
  return [
    declaredRecord(id, cases: [for (final name in cases) id.member(name)]),
    for (final name in cases)
      publishedType(
        id.member(name),
        representation: skir.RepresentationTemplate.createScalar(
          kind: skir.ScalarKind.unit,
        ),
        parents: [_named(id)],
      ),
  ];
}

/// The value of the case [name] of the enum [type].
skir.DataValue enumValue(Object type, String name) =>
    skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: _id(type).member(name),
        arguments: const [],
      ),
      payload: skir.DataValue.unit,
    );

/// The ready scalar type [type] of [kind].
skir.PublishedType declaredScalar(Object type, skir.ScalarKind kind) =>
    publishedType(
      _id(type),
      representation: skir.RepresentationTemplate.createScalar(kind: kind),
    );

/// [definition] published as ready, with the fields its record
/// representation declares and [display], the default display unless given:
/// a type whose definition the test already holds, such as one decoded from
/// a shared fixture.
skir.PublishedType declaredDefinition(
  skir.TypeDefinition definition, {
  skir.TypeDisplay? display,
}) => publishedType(
  definition.id,
  representation: definition.representation,
  parameters: definition.parameters,
  parents: definition.parents,
  fields: [
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
  display: display,
);

/// The ready collection type [type] of [item]s, a list unless [kind] says
/// otherwise.
skir.PublishedType declaredCollection(
  Object type,
  Object item, {
  skir.CollectionKind kind = skir.CollectionKind.list,
}) => publishedType(
  _id(type),
  representation: skir.RepresentationTemplate.createSequence(
    item: typeTemplateOf(item),
    kind: kind,
  ),
);

/// The ready map type [type] from [key]s to [value]s.
skir.PublishedType declaredMap(
  Object type, {
  required Object key,
  required Object value,
}) => publishedType(
  _id(type),
  representation: skir.RepresentationTemplate.createMapping(
    key: typeTemplateOf(key),
    value: typeTemplateOf(value),
  ),
);

/// The ready link type [type] through [endpoint] to a [target].
skir.PublishedType declaredLink(
  Object type, {
  required String endpoint,
  required Object target,
}) => publishedType(
  _id(type),
  representation: skir.RepresentationTemplate.createLink(
    endpoint: skir.EndpointId(value: endpoint),
    target: typeTemplateOf(target),
  ),
);

/// The endpoint [id] of a relation at a [resource], one per resource unless
/// [cardinality] says otherwise, cleared when its counterpart is deleted
/// unless [onDelete] says otherwise. The relation it joins places it.
skir.EndpointDefinition endpointOf(
  String id,
  Object resource, {
  skir.EndpointCardinality cardinality = skir.EndpointCardinality.one,
  skir.RelationDeletePolicy onDelete = skir.RelationDeletePolicy.clear,
}) => skir.EndpointDefinition(
  id: skir.EndpointId(value: id),
  slot: skir.EndpointSlot.first,
  resource: _named(resource),
  cardinality: cardinality,
  onDelete: onDelete,
);

/// The relation [id] joining its [first] and [second] endpoint, in the
/// relation [families].
skir.RelationContract declaredRelation(
  String id,
  skir.EndpointDefinition first,
  skir.EndpointDefinition second, {
  List<skir.RelationFamilyId> families = const [],
}) => skir.RelationContract(
  id: skir.RelationId(value: id),
  first: (first.toMutable()..slot = skir.EndpointSlot.first).toFrozen(),
  second: (second.toMutable()..slot = skir.EndpointSlot.second).toFrozen(),
  families: families,
);

/// Binds [endpoint] to the value a [resource] holds at [path], whose names
/// are fields and whose [skir.FieldPatternSegment.items] reads each item of a
/// collection; the value is declared by [owner], the [resource] unless
/// given, and links to a [target].
skir.EndpointBindingTemplate endpointBinding(
  String endpoint, {
  required String resource,
  required List<Object> path,
  required Object target,
  String? owner,
}) => skir.EndpointBindingTemplate(
  endpoint: skir.EndpointId(value: endpoint),
  containingResource: _named(resource),
  valueOwner: testTypeId(owner ?? resource),
  relativePath: skir.RelativeFieldPattern(
    segments: [
      for (final segment in path)
        switch (segment) {
          final String field => skir.FieldPatternSegment.createField(
            name: field,
          ),
          final skir.FieldPatternSegment segment => segment,
          _ => throw ArgumentError.value(segment, "path", "is no segment"),
        },
    ],
  ),
  target: typeTemplateOf(target),
  containsCollection: path.contains(skir.FieldPatternSegment.items),
);

/// The catalog generation authored content is saved under unless a test names
/// another; [authoredCatalog] defaults to it.
final realmFixtureGeneration = skir.CatalogGeneration(value: "fixture");

/// The checked catalog of [generation] declaring [types], [relations] and
/// the [endpoints] binding them. Each type also gets the fields and the
/// ancestors of the parents it refines, its own fields after theirs; its
/// direct parents come first among its ancestors.
///
/// Builds on [testCheckedCatalog], which checks a [testCatalogSnapshot]: use
/// those directly for a catalog whose types need no resolved ancestry, and
/// `authoredCatalog(const [])` for an empty catalog of the fixture generation.
CheckedEditorCatalog authoredCatalog(
  List<skir.PublishedType> types, {
  List<skir.RelationContract> relations = const [],
  List<skir.EndpointBindingTemplate> endpoints = const [],
  String generation = "fixture",
}) {
  final declared = {for (final type in types) type.definition.id: type};
  List<skir.NamedTypeTemplate> ancestors(skir.PublishedType type) {
    final found = <skir.NamedTypeTemplate>[...type.definition.parents];
    for (final parent in type.definition.parents) {
      if (declared[parent.definition] case final skir.PublishedType known) {
        for (final ancestor in ancestors(known)) {
          if (!found.any((seen) => seen.definition == ancestor.definition)) {
            found.add(ancestor);
          }
        }
      }
    }
    return found;
  }

  List<skir.EffectiveFieldTemplate> fields(skir.PublishedType type) {
    final own = type.effectiveFields.toList();
    final inherited = [
      for (final parent in type.definition.parents)
        if (declared[parent.definition] case final skir.PublishedType known)
          ...fields(known),
    ];
    return [
      for (final field in inherited)
        if (!own.any((candidate) => candidate.key == field.key)) field,
      ...own,
    ];
  }

  return testCheckedCatalog(
    generation: skir.CatalogGeneration(value: generation),
    types: [
      for (final type in types)
        (type.toMutable()
              ..ancestorTemplates = ancestors(type)
              ..effectiveFields = fields(type))
            .toFrozen(),
    ],
    relations: relations,
    endpointBindings: endpoints,
  );
}

/// Each field of [texts] as a text value, in order.
Map<String, skir.DataValue> texts(Map<String, String> texts) => {
  for (final MapEntry(:key, :value) in texts.entries) key: textValue(value),
};

/// The `typewriter.List` type of [item] items.
skir.NamedTypeUse listTypeOf(skir.TypeUse item) => skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "typewriter", name: "List"),
    revision: 1,
  ),
  arguments: [item],
);

/// A `typewriter.List` of texts holding [values] in order, each item
/// identified by its own text, as a typed list field holds them.
skir.DataValue typedTextList(List<String> values) => skir.DataValue.createNamed(
  actualType: listTypeOf(skir.TypeUse.wrapScalar(skir.ScalarKind.text)),
  payload: textList(values),
);

/// The location of the value at [fields] inside the resource [resource]:
/// each name a field below the one before it.
skir.ValueLocation valueAt(Object resource, List<String> fields) =>
    skir.ValueLocation(
      resource: switch (resource) {
        final skir.ResourceId id => id,
        _ => skir.ResourceId(value: "$resource"),
      },
      path: skir.ValuePath(
        segments: [
          for (final name in fields) skir.PathSegment.createField(name: name),
        ],
      ),
    );

/// One authored resource: a record of [fields], configured as [type] or
/// untyped when absent.
skir.AuthoringResource authoredRecord(
  Object id,
  Map<String, skir.DataValue> fields, {
  skir.NamedTypeUse? type,
}) => skir.AuthoringResource(
  id: switch (id) {
    final skir.ResourceId id => id,
    _ => skir.ResourceId(value: "$id"),
  },
  content: skir.AuthoringRecord(
    types: const [],
    configuration: type == null
        ? skir.TypeSelection.defaultInstance
        : selectionOfUse(type),
    fields: [
      for (final MapEntry(:key, :value) in fields.entries)
        skir.FieldValue(name: key, value: value),
    ],
  ),
);

/// Authored content as the Realm saved it: [resources] and [links] under a
/// catalog of [generation].
final class AuthoredDoc {
  AuthoredDoc._(this.resources, this.links, this.generation, this._catalog);

  /// The resources, in order.
  final List<skir.AuthoringResource> resources;

  /// The links between the resources.
  final List<skir.LinkProjection> links;

  /// The catalog generation the content was saved under.
  final skir.CatalogGeneration generation;

  final CheckedEditorCatalog? _catalog;

  /// The catalog typing the content: the one given, or one of [generation]
  /// that declares nothing, so only edits by location apply.
  CheckedEditorCatalog get catalog =>
      _catalog ?? authoredCatalog(const [], generation: generation.value);

  /// The saved state the Realm reports for the content.
  skir.AuthoringState get state => skir.AuthoringState(
    confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
    generation: generation,
    resources: resources,
    links: links,
    findings: const [],
  );

  /// The document the panel reads the content through.
  AuthoringDocument get document => AuthoringDocument(
    catalog: catalog,
    entries: {for (final resource in resources) resource.id: resource},
    links: links,
  );

  /// A fresh edit of the saved content; each read starts a new one.
  AuthoringEdit get edit => AuthoringEdit.fromState(state, catalog: _catalog);
}

/// Authored content holding [resources] and [links], typed by [catalog] or,
/// without one, by an empty catalog of [generation].
AuthoredDoc authoredDoc(
  List<skir.AuthoringResource> resources, {
  List<skir.LinkProjection> links = const [],
  CheckedEditorCatalog? catalog,
  skir.CatalogGeneration? generation,
}) => AuthoredDoc._(
  resources,
  links,
  catalog?.snapshot.generation ?? generation ?? realmFixtureGeneration,
  catalog,
);
