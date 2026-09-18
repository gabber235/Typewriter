part of "tags.dart";

/// Shared presentation collection used by tag search and inheritance graphs.
///
/// Each row is keyed by a tag reference and exposes direct parent references.
/// The collection is rebuilt from the current tag projection, so it is a read
/// model rather than an owner of tag state. Search matches names case
/// insensitively. During parent editing, [selectable] marks candidates that
/// pass the local graph safety rules.
const tagCollectionSourceId = PresentationCollectionSourceId("realm.tags");
const tagInheritsRelationId = PresentationCollectionRelationId("inherits");
const tagCollectionRowBindingId = BindingId(40);
const tagParentReferencePolicyId = ReferencePolicyId("tag.parents.acyclic");

final tagReferenceType = ReferenceType(target: referenceResourceTypes.tag);

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

/// Builds the read model consumed by inspector reference controls and graphs.
extension TagPresentationCollection on Iterable<Tag> {
  PresentationCollectionSource presentationCollection({
    skir.RecordId? editingTagId,
    Iterable<skir.RecordId> existingParentIds = const [],
  }) {
    final existingParents = existingParentIds.toSet();
    final rows = map(
      (tag) => tag._collectionRow(
        selectable:
            tag.unavailableParentReason(
              this,
              editingTagId: editingTagId,
              existingParents: existingParents,
            ) ==
            null,
      ),
    ).toList(growable: false);
    return LocalPresentationCollectionSource(
      id: tagCollectionSourceId,
      schema: tagCollectionSchema,
      rows: rows,
      registry: TypeRegistry(
        TypeCatalog([
          ...referenceResourceTypes.definitions,
          tagInspectorTypeDefinition,
        ]),
      ),
      searchPredicate: (row, query) {
        if (row is! RecordValue) return false;
        final name = row.fields["name"];
        return name?.asStringOrNull?.toLowerCase().contains(
              query.normalizedQuery.toLowerCase(),
            ) ??
            false;
      },
    );
  }
}

extension on Tag {
  RecordValue _collectionRow({required bool selectable}) => RecordValue({
    "key": ReferenceValue(tagId),
    "name": name.asValue,
    "color": color.asValue,
    "parents": ListValue(parentIds.map(ReferenceValue.new).toList()),
    "selectable": selectable.asValue,
  });
}

/// Explains why this tag cannot be selected as a direct parent.
///
/// A null result means selectable. Existing parents remain selectable because
/// the same gesture removes their link. Missing ancestry is rejected rather
/// than guessed safe, matching the mutation decision used by graph drops.
extension TagParentCandidate on Tag {
  String? unavailableParentReason(
    Iterable<Tag> tags, {
    required skir.RecordId? editingTagId,
    required Set<skir.RecordId> existingParents,
  }) {
    if (editingTagId == null) return null;
    if (tagId == editingTagId) return "A Tag cannot inherit itself";
    if (existingParents.contains(tagId)) return null;
    final byId = {for (final tag in tags) tag.tagId: tag};
    final descendant = _isAncestor(
      byId,
      tagId: tagId,
      ancestorId: editingTagId,
    );
    if (descendant ?? true) return "A descendant cannot become a parent";
    return null;
  }
}

ReferenceCandidatePolicy tagParentReferencePolicy(Ref ref) =>
    CallbackReferenceCandidatePolicy((context) {
      final tags = ref.read(projectedTagsProvider).value;
      if (tags == null) {
        return const ReferenceCandidateDecision.unavailable(
          ReferencePolicyIssue(
            code: "tag.parents.loading",
            message: "Tag ancestry is unavailable",
          ),
        );
      }
      final ownerIds = _tagOwnerIds(context.owner).toList(growable: false);
      if (ownerIds.isEmpty) {
        return const ReferenceCandidateDecision.unavailable(
          ReferencePolicyIssue(
            code: "tag.parents.ownerUnavailable",
            message: "The edited Tag is unavailable",
          ),
        );
      }
      final byId = {for (final tag in tags) tag.tagId: tag};
      final candidate = byId[context.candidate.id];
      if (candidate == null) {
        return const ReferenceCandidateDecision.rejected(
          ReferencePolicyIssue(
            code: "tag.parents.candidateMissing",
            message: "The candidate Tag no longer exists",
          ),
        );
      }
      for (final ownerId in ownerIds) {
        final owner = byId[ownerId];
        if (owner == null) {
          return const ReferenceCandidateDecision.unavailable(
            ReferencePolicyIssue(
              code: "tag.parents.ownerMissing",
              message: "The edited Tag no longer exists",
            ),
          );
        }
        final reason = candidate.unavailableParentReason(
          tags,
          editingTagId: ownerId,
          existingParents: owner.parentIds.toSet(),
        );
        if (reason != null) {
          return ReferenceCandidateDecision.rejected(
            ReferencePolicyIssue(code: "tag.parents.cycle", message: reason),
          );
        }
      }
      return const ReferenceCandidateDecision.allowed();
    });

Iterable<skir.RecordId> _tagOwnerIds(EditOwner? owner) sync* {
  if (owner case MultiEditOwner(:final owners)) {
    for (final member in owners) {
      yield* _tagOwnerIds(member);
    }
    return;
  }
  if (owner case TransactionalEditorSource(resource: final resource?)) {
    final identity = resource.key.identity;
    if (identity is skir.RecordId && identity.table == "tag") yield identity;
  }
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

// This source is intentionally eager. The Realm session currently exposes the
// complete tag set, which keeps search and graph validation consistent.
