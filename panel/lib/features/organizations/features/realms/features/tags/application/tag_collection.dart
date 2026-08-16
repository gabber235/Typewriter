part of "tags.dart";

const tagCollectionSourceId = PresentationCollectionSourceId("realm.tags");
const tagInheritsRelationId = PresentationCollectionRelationId("inherits");
const tagCollectionRowBindingId = BindingId(40);

final tagReferenceType = NamedType(
  standardTypeRefs.refTo(NamedType(tagInspectorTypeRef)),
);

final tagCollectionRowType = RecordType(
  fields: {
    "key": TypeField(name: "key", type: tagReferenceType),
    "name": TypeField(name: "name", type: StringType()),
    "color": TypeField(name: "color", type: NamedType(standardTypeRefs.color)),
    "parents": TypeField(
      name: "parents",
      type: ListType(element: tagReferenceType),
    ),
    "selectable": TypeField(name: "selectable", type: BooleanType()),
    "unavailableReason": TypeField(
      name: "unavailableReason",
      type: NamedType(standardTypeRefs.optionOf(const StringType())),
    ),
  },
);

final tagCollectionSchema = PresentationCollectionSchema(
  rowType: tagCollectionRowType,
  keyType: tagReferenceType,
  rowBindingId: tagCollectionRowBindingId,
  key: _tagRowField("key", tagReferenceType),
  relations: [
    PresentationCollectionRelation(
      id: tagInheritsRelationId,
      targets: _tagRowField("parents", ListType(element: tagReferenceType)),
    ),
  ],
);

PresentationCollectionSource tagPresentationCollection(
  Iterable<Tag> tags, {
  skir.RecordId? editingTagId,
  Iterable<skir.RecordId> existingParentIds = const [],
}) {
  final existingParents = existingParentIds.toSet();
  final rows = tags
      .map(
        (tag) => _tagCollectionRow(
          tag,
          unavailableReason: _tagUnavailableReason(
            tags,
            editingTagId: editingTagId,
            candidate: tag,
            existingParents: existingParents,
          ),
        ),
      )
      .toList(growable: false);
  return LocalPresentationCollectionSource(
    id: tagCollectionSourceId,
    schema: tagCollectionSchema,
    rows: rows,
    registry: TypeRegistry(TypeCatalog([tagInspectorTypeDefinition])),
    searchPredicate: (row, query) {
      if (row is! RecordValue) return false;
      final name = row.fields["name"];
      return name is StringValue &&
          name.value.toLowerCase().contains(
            query.normalizedQuery.toLowerCase(),
          );
    },
  );
}

RecordValue _tagCollectionRow(Tag tag, {String? unavailableReason}) =>
    RecordValue({
      "key": StringValue(tag.tagId.id),
      "name": StringValue(tag.name),
      "color": tag.color.integerValue,
      "parents": ListValue(
        tag.parentIds.map((parent) => StringValue(parent.id)).toList(),
      ),
      "selectable": BooleanValue(unavailableReason == null),
      "unavailableReason": _optionalTagText(unavailableReason),
    });

String? _tagUnavailableReason(
  Iterable<Tag> tags, {
  required skir.RecordId? editingTagId,
  required Tag candidate,
  required Set<skir.RecordId> existingParents,
}) {
  if (editingTagId == null) return null;
  if (candidate.tagId == editingTagId) return "A Tag cannot inherit itself";
  if (existingParents.contains(candidate.tagId)) return null;
  final byId = {for (final tag in tags) tag.tagId: tag};
  final descendant = _isAncestor(
    byId,
    tagId: candidate.tagId,
    ancestorId: editingTagId,
  );
  if (descendant ?? true) {
    return "A descendant cannot become a parent";
  }
  return null;
}

DataValue _optionalTagText(String? value) {
  const valueType = StringType();
  if (value == null) {
    return PolymorphicValue(
      concreteType: standardTypeRefs.noneOf(valueType),
      value: const UnitValue(),
    );
  }
  return PolymorphicValue(
    concreteType: standardTypeRefs.someOf(valueType),
    value: RecordValue({"value": StringValue(value)}),
  );
}

TypedExpression _tagRowField(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(
          bindingId: tagCollectionRowBindingId,
          path: DataPath.root.field(name),
        ),
      ),
    );

// TODO: Replace this eager Tag collection with a Realm backed collection
// source when Realm Tag counts make local enumeration unsuitable.
