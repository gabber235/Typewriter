part of "checked_editor_catalog.dart";

/// One ownership relation: the [owner] endpoint has one resource, which owns
/// the many resources of the [member] endpoint.
@freezed
abstract class OwnershipRelation with _$OwnershipRelation {
  const factory OwnershipRelation({
    required skir.RelationId relation,
    required skir.EndpointDefinition owner,
    required skir.EndpointDefinition member,
  }) = _OwnershipRelation;
}

/// A link field through which a resource owns other resources, such as the
/// pages of a Book. New members join the owner by linking back through
/// [ownership]'s member endpoint.
@freezed
abstract class OwningField with _$OwningField {
  const factory OwningField({
    required String field,
    required OwnershipRelation ownership,
  }) = _OwningField;

  const OwningField._();

  /// The type every member of this field has, such as Page for Book.pages.
  skir.TypeDefinitionId get memberType => ownership.member.resource.definition;

  /// The field path below the owner, such as `pages`.
  skir.ValuePath get path =>
      skir.ValuePath(segments: [skir.PathSegment.createField(name: field)]);
}

extension ResourceOwnershipRelation on skir.RelationContract {
  /// Whether this relation belongs to the contract's resource ownership family.
  bool get ownsResources => families.contains(skir.resourceOwnershipFamily);
}

/// The realm's structure as the catalog declares it: one root type owning the
/// section types, and ownership relations below them. Nothing here names a
/// library type; every fact comes from relation families and the published
/// realm root.
extension RealmStructureCatalog on CheckedEditorCatalog {
  /// Ownership relations with exactly one owner endpoint, in catalog order.
  List<OwnershipRelation> get ownershipRelations => [
    for (final relation in snapshot.relations)
      if (relation.ownsResources)
        if (relation.first.cardinality == skir.EndpointCardinality.one &&
            relation.second.cardinality == skir.EndpointCardinality.many)
          OwnershipRelation(
            relation: relation.id,
            owner: relation.first,
            member: relation.second,
          )
        else if (relation.second.cardinality == skir.EndpointCardinality.one &&
            relation.first.cardinality == skir.EndpointCardinality.many)
          OwnershipRelation(
            relation: relation.id,
            owner: relation.second,
            member: relation.first,
          ),
  ];

  /// Whether [selection] is the realm root type.
  bool isRealmRoot(skir.TypeSelection selection) =>
      nominalDefinitions(selection).contains(snapshot.realmRoot);

  /// Whether [selection] is a section type: a member type of an ownership
  /// relation whose owner is the realm root.
  bool isRealmSection(skir.TypeSelection selection) {
    final nominal = nominalDefinitions(selection);
    return _sectionBases.any(nominal.contains);
  }

  Set<skir.TypeDefinitionId> get _sectionBases => {
    for (final ownership in ownershipRelations)
      if (isNominalSubtype(
        snapshot.realmRoot,
        ownership.owner.resource.definition,
      ))
        ownership.member.resource.definition,
  };

  /// Concrete, ready resource types: the realm root and every concrete record
  /// type that is a member of an ownership relation, in catalog order.
  List<skir.TypeDefinitionId> get concreteResourceTypes {
    final members = {
      for (final ownership in ownershipRelations)
        ownership.member.resource.definition,
    };
    bool concreteRecord(skir.PublishedType published) =>
        published.status == skir.DeclarationStatus.ready &&
        switch (published.definition.representation) {
          skir.RepresentationTemplate_recordWrapper(:final value) =>
            !value.abstract_,
          _ => false,
        };
    return [
      for (final published in snapshot.types)
        if (concreteRecord(published) &&
            (published.definition.id == snapshot.realmRoot ||
                members.any(
                  (member) => isNominalSubtype(published.definition.id, member),
                )))
          published.definition.id,
    ];
  }

  /// Concrete resource types a person may create: everything except the realm
  /// root and its sections, which the realm creates itself.
  Iterable<skir.TypeDefinitionId> get creatableTypes =>
      concreteResourceTypes.where((type) {
        final selection = beginSelection(type);
        return !isRealmRoot(selection) && !isRealmSection(selection);
      });

  /// The link fields through which resources of [selection] own others, in
  /// field order. A field qualifies when its links are the owner endpoint of
  /// an ownership relation.
  List<OwningField> owningFields(skir.TypeSelection selection) {
    final relations = {
      for (final ownership in ownershipRelations) ownership.owner.id: ownership,
    };
    final fields = <OwningField>[];
    for (final binding in endpointBindings(selection)) {
      final ownership = relations[binding.template.endpoint];
      final field =
          switch (binding.template.relativePath.segments.firstOrNull) {
            skir.FieldPatternSegment_fieldWrapper(:final value) => value.name,
            _ => null,
          };
      if (ownership == null || field == null) continue;
      if (fields.any((existing) => existing.field == field)) continue;
      fields.add(OwningField(field: field, ownership: ownership));
    }
    return fields;
  }

  /// The owning field of [selection] at [path], such as Book.pages.
  OwningField? owningFieldAt(
    skir.TypeSelection selection,
    skir.ValuePath path,
  ) {
    final field = switch (path.segments.singleOrNull) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    return owningFields(selection)
        .where((candidate) => candidate.field == field)
        .firstOrNull;
  }

  /// Whether the catalog declares a presentation for [selection] in exactly
  /// [role]. Role fallbacks do not count, so a resource has a workspace or
  /// navigator only when its type declares one.
  bool declaresPresentation(
    skir.TypeSelection selection,
    skir.PresentationRole role,
  ) => _selectWithinRole(selection, role) is! MissingEditorPresentation;
}
