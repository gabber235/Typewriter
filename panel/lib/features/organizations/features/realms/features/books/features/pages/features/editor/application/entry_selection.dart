part of "entries.dart";

/// Stable selection identity for an entry element.
///
/// The resource identity uses the authoring element record, allowing shared
/// selection infrastructure to resolve the entry without owning its data.
class EntryIdentifier extends SelectableIdentifier
    implements GraphDragData, GraphIdentifier {
  const EntryIdentifier(this.id, {this.pageId});

  final String? pageId;

  @override
  final String id;

  @override
  Object get resourceId => recordId("element:$id");

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
    final identity = EntryIdentifier(id, pageId: location.pageId);

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
  Widget? buildInspectorHeader(EditOwner owner) {
    return EntryHeader(
      id: id.id,
      name: name,
      color: definition.elementDefinition.color,
    );
  }

  @override
  EditableResource get resource => target.resource;
  @override
  EditorSnapshot get snapshot => target.snapshot;

  @override
  String toString() => "EntrySelection($id)";
}

/// Inspector header that identifies the selected entry and its catalog type.
class EntryHeader extends HookWidget {
  const EntryHeader({
    required this.id,
    required this.name,
    required this.color,
    super.key,
  });

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: name, color: color),
        const SizedBox(height: 8),
        Identifier(id: id),
      ],
    );
  }
}
