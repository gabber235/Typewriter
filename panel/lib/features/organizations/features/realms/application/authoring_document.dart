part of "realm_edit_model.dart";

/// A complete immutable observation, paired with the catalog that interprets it.
///
/// Display queries use this value without collecting save expectations. Resource
/// definitions and unfinished authored values survive every working publication.
@freezed
abstract class AuthoringDocument
    with _$AuthoringDocument
    implements PortableAuthoringView {
  const factory AuthoringDocument({
    required CheckedEditorCatalog catalog,
    required Map<skir.ResourceId, skir.AuthoringResource> entries,
    required List<skir.LinkProjection> links,
    @Default(0) int revision,
    @Default([]) List<LocatedInitializationFinding> initializationFindings,
  }) = _AuthoringDocument;

  const AuthoringDocument._();

  factory AuthoringDocument.fromState(
    skir.AuthoringState state, {
    required CheckedEditorCatalog catalog,
  }) {
    if (state.generation != catalog.snapshot.generation) {
      throw StateError("The authoring state and catalog do not match");
    }
    return AuthoringDocument(
      catalog: catalog,
      entries: Map.unmodifiable({
        for (final entry in state.resources) entry.id: entry,
      }),
      links: List.unmodifiable(state.links),
    );
  }

  AuthoringRelationIndex get relations =>
      AuthoringRelationIndex.fromDocument(this);

  @override
  skir.CatalogGeneration get generation => catalog.snapshot.generation;
  skir.AuthoringResource? entry(skir.ResourceId id) => entries[id];
  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => entries[id]?.content;
  @override
  Map<skir.ResourceId, skir.AuthoringRecord> get resources => Map.unmodifiable({
    for (final entry in entries.entries) entry.key: entry.value.content,
  });
  @override
  skir.DataValue defaultValue(skir.TypeUse? type) =>
      _AuthoringDefaults(catalog)._defaultForType(type, const {});
  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) =>
      resource(location.resource)?.readAt(location.path) ??
      const PortablePathUnavailable("The resource is absent");
}

@freezed
abstract class AuthoringScope with _$AuthoringScope {
  const factory AuthoringScope({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
  }) = _AuthoringScope;
}

/// A preparation finding witnessed by the value returned for its target.
/// Later edits invalidate this evidence instead of moving the finding forward.
@freezed
abstract class LocatedInitializationFinding
    with _$LocatedInitializationFinding {
  const factory LocatedInitializationFinding({
    required skir.ValueLocation location,
    required skir.InitializationDiagnostic diagnostic,
    required skir.DiagnosticEvidence evidence,
  }) = _LocatedInitializationFinding;
}
