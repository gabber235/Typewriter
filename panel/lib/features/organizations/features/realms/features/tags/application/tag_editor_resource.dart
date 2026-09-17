part of "tag_selectable.dart";

/// Editor snapshot for one tag at one authoring session revision.
///
/// The document stores inspector shaped data, while [tag] retains the identity
/// and typed model needed to encode a patch. Width and height are positive in
/// valid drafts. Parent edits merge as a set so concurrent membership changes
/// can be reconciled according to editor merge policy.
final class TagEditorSnapshot extends EditorSnapshot {
  const TagEditorSnapshot(this.tag, this.revision);
  final Tag tag;
  final int revision;
  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(tagInspectorTypeRef),
    typeCatalog: _tagInspectorCatalog,
    confirmedValue: tag.inspectorValue,
    revision: revision,
    mergePolicies: {DataPath.root.field("parents"): EditorMergePolicy.set},
  );

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    final result = super.validate(path, value);
    if (result is! AppliedEditorMutation || value is! IntegerValue) {
      return result;
    }
    final widthPath = DataPath.root.field("layout").field("width");
    final heightPath = DataPath.root.field("layout").field("height");
    if ((path == widthPath || path == heightPath) && value.value < BigInt.one) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Tag dimensions must be greater than zero",
          path: path,
        ),
      ]);
    }
    return result;
  }

  @override
  List<TypeDiagnostic> validateDraft(DataValue value) =>
      tag.withInspectorValue(value) == null
      ? [
          const TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "The Tag value is invalid",
          ),
        ]
      : const [];
}

/// Adapts a Realm tag to the shared authoritative editor pipeline.
///
/// Snapshot reads search the library scope for the matching tag. Applied
/// upserts replace the editor snapshot at the response revision, removals
/// confirm deletion, and unrelated responses return null so the shared adapter
/// performs one authoritative refresh. [operation] preserves expected field
/// values when translating an editor commit.
final class TagEditorResource extends AuthoringEditorResource {
  const TagEditorResource(super.repository, super.id);
  @override
  skir.AuthoringSnapshotScope get scope => skir.AuthoringSnapshotScope.library_;
  @override
  EditorSnapshot? project(skir.AuthoringSnapshot snapshot) {
    for (final slice in snapshot.slices) {
      if (slice case skir.AuthoringSnapshotSlice_libraryWrapper(:final value)) {
        for (final tag in value.tags) {
          if (tag.id == id) {
            return TagEditorSnapshot(Tag.fromWire(tag), snapshot.sequence);
          }
        }
      }
    }
    return null;
  }

  @override
  EditorSnapshot? projectApplied(
    skir.AuthoringChanged change,
    EditorSnapshot submitted,
  ) {
    for (final resource in change.changes) {
      switch (resource) {
        case skir.AuthoringResourceChange_upsertTagWrapper(:final value):
          if (value.id == id) {
            return TagEditorSnapshot(Tag.fromWire(value), change.sequence);
          }
        case skir.AuthoringResourceChange_removeTagWrapper(:final value):
          if (value == id) return null;
        case skir.AuthoringResourceChange_unknown() ||
            skir.AuthoringResourceChange_upsertBookWrapper() ||
            skir.AuthoringResourceChange_removeBookWrapper() ||
            skir.AuthoringResourceChange_upsertPageWrapper() ||
            skir.AuthoringResourceChange_removePageWrapper() ||
            skir.AuthoringResourceChange_upsertElementWrapper() ||
            skir.AuthoringResourceChange_removeElementWrapper():
      }
    }
    return null;
  }

  @override
  skir.AuthoringOperation operation(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) {
    final current = snapshot as TagEditorSnapshot;
    final next = current.tag.withInspectorValue(commit.rootValue);
    final expected = current.tag.withInspectorValue(commit.baseValue);
    if (next == null || expected == null) {
      throw StateError("The Tag value is invalid");
    }
    return tagPatchOperation(next, expected: expected);
  }
}
