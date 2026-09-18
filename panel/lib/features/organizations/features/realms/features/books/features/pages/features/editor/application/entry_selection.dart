part of "entries.dart";

/// Stable selection identity for an entry element.
///
/// The resource identity uses the authoring element record, allowing shared
/// selection infrastructure to resolve the entry without owning its data.
class EntryIdentifier extends SelectableIdentifier
    implements GraphDragData, GraphIdentifier, ReferenceResourceDragData {
  const EntryIdentifier(this.id, {this.pageId, this.elementType});

  final String? pageId;
  final ResolvedTypeRef? elementType;

  @override
  final String id;

  @override
  Object get resourceId => recordId("element:$id");

  @override
  skir.RecordId get referenceId => recordId("element:$id");

  @override
  List<ResolvedTypeRef> get referenceTypes => [?elementType];

  @override
  AsyncValue<Selectable<EntryIdentifier>> create(Ref ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return AsyncValue.error(
        ApiException.badRequest("No realm selected"),
        StackTrace.current,
      );
    }
    final index = ref.watch(
      authoringEntryIndexProvider(organizationId, realmId),
    );
    if (index.mapUnready<Selectable<EntryIdentifier>>() case final state?) {
      return state;
    }
    final indexed = index.requireValue;
    final location = indexed.value[id];

    if (location == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }

    final state = ref.watch(authoringSessionProvider(organizationId, realmId));
    final repository = ref
        .watch(resourceRepositoriesProvider)
        .authoring(organizationId, realmId);

    final value = location.definition;
    final identity = EntryIdentifier(
      id,
      pageId: location.pageId,
      elementType: value.elementDefinition.rootType,
    );

    final catalogState = ref.watch(
      realmEditorCatalogForTypeProvider(value.elementDefinition.rootType),
    );

    return catalogState.resolveElement(
      value.elementDefinition,
      (catalog, presentations) => EntrySelection(
        target: authoringElementTarget(
          repository: repository,
          state: state,
          identity: identity,
          pageId: location.pageId,
          label: value.name,
          document: EditorDocument(
            rootType: NamedType(value.elementDefinition.rootType),
            typeCatalog: catalog,
            confirmedValue: value.data,
            revision: indexed.revision,
          ),
        ),
        id: identity,
        definition: value,
        typeCatalog: catalog,
        presentations: presentations,
        selectionCapabilities: [identity.deleteCapability(ref)],
      ),
    );
  }

  /// Creates deletion capability for this resolved entry identity.
  ///
  /// The callback captures the resolved page, then validates the live index
  /// before submitting through that page owner.
  DeleteSelectionCapability deleteCapability(Ref ref) {
    final expectedPageId = pageId;
    if (expectedPageId == null) {
      throw StateError("Cannot delete an unresolved entry identifier");
    }
    return DeleteSelectionCapability(
      onDelete: () => _delete(ref, expectedPageId),
    );
  }

  Future<void> _delete(Ref ref, String expectedPageId) async {
    await ref.withReadyPageElements(expectedPageId, (elements) {
      final organizationId = ref.read(organizationIdProvider);
      final realmId = ref.read(realmIdProvider);
      if (organizationId == null) throw ApiException.noOrganization();
      if (realmId == null) throw ApiException.badRequest("No realm selected");

      final current = ref
          .read(realmEntryIndexProvider(organizationId, realmId))
          .requireValue[id];
      if (current == null) throw ApiException.notFound("Entry");
      if (current.pageId != expectedPageId) {
        throw ApiException.conflict("The entry moved to another page");
      }
      return elements.deleteAll([id]);
    });
  }

  @override
  GraphIdentifier get graphId => this;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EntryIdentifier && other.id == id);

  @override
  String toString() => "EntryIdentifier($id)";
}

/// Selectable adapter that connects an entry identity to its editor document,
/// inspector header, and authoring target.
class EntrySelection extends EditableSelectable<EntryIdentifier> {
  const EntrySelection({
    required this.target,
    required this.id,
    required this.definition,
    required this.typeCatalog,
    required this.presentations,
    required this.selectionCapabilities,
  });

  final EditorTarget target;

  @override
  final EntryIdentifier id;
  final EntryDefinition definition;

  @override
  final TypeCatalog typeCatalog;
  @override
  final List<PresentationDefinition> presentations;
  final List<SelectionCapability> selectionCapabilities;

  @override
  String get name => definition.name;

  @override
  EditorDocument get document => target.document;

  @override
  DataPath get presentationPath => elementValuePath;

  @override
  ResolvedTypeRef get rootType => definition.elementDefinition.rootType;

  @override
  List<SelectionCapability> get capabilities => selectionCapabilities;

  @override
  PresentationModel buildPresentation(EditorOwnerScope owners) {
    return super.buildPresentation(owners).withEntryIdentityEditor();
  }

  @override
  Widget? buildInspectorHeader(EditOwner owner) => EntryHeader(
    id: id.id,
    name: name,
    color: definition.elementDefinition.color,
    owner: ProjectedEditOwner(owner, elementValuePath),
  );

  @override
  EditableResource get resource => target.resource;
  @override
  EditorSnapshot get snapshot => target.snapshot;

  @override
  String toString() => "EntrySelection($id)";
}

extension EntryPresentationModel on PresentationModel {
  PresentationModel withEntryIdentityEditor() {
    final nameBinding = const BindingReference(bindingId: BindingId(0))
        .at(DataPath.root.field("name"));
    final content = root.withoutEntryIdentityFields();
    return copyWith(
      root: PresentationNode(
        id: "entry.editor",
        element: ColumnElement(
          spacing: 12,
          children: [
            PresentationNode(
              id: "entry.name",
              element: TypedFieldElement(
                binding: nameBinding,
                expectedType: const StringType(),
                presentation: PresentationNode(
                  id: "entry.name.control",
                  element: TextInputElement(
                    control: BoundControl(
                      binding: nameBinding,
                      label: "Name".asStringLiteral,
                    ),
                    multiline: false,
                  ),
                ),
              ),
            ),
            ?content,
          ],
        ),
      ),
    );
  }
}

extension PresentationNodeIdentityFields on PresentationNode {
  PresentationNode? withoutEntryIdentityFields() {
    final record = element;
    if (record is! RecordInputElement) return this;
    final fields = record.fieldPresentation;
    final column = fields?.element;
    if (fields == null || column is! ColumnElement) return this;
    final identityPaths = {
      DataPath.root.field("id"),
      DataPath.root.field("name"),
    };
    final children = column.children.where((node) {
      final element = node.element;
      return element is! TypedFieldElement ||
          !identityPaths.contains(element.binding.path);
    }).toList();
    if (children.isEmpty) return null;
    return copyWith(
      element: record.copyWith(
        fieldPresentation: fields.copyWith(
          element: column.copyWith(children: children),
        ),
      ),
    );
  }
}

/// Static entry header used by stories and read only surfaces.
class EntryHeader extends StatelessWidget {
  const EntryHeader({
    required this.id,
    required this.name,
    required this.color,
    this.owner,
    super.key,
  });

  final String id;
  final String name;
  final Color color;
  final EditOwner? owner;

  @override
  Widget build(BuildContext context) {
    final owner = this.owner;
    if (owner == null) {
      return InspectorHeader(id: id, name: name, color: color);
    }
    return ManagedInspectorHeader(
      id: id,
      owner: owner,
      fallbackName: name,
      fallbackColor: color,
      colorField: null,
      nameFormatter: null,
    );
  }
}
