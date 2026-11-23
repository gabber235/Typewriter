part of "realm_edit_model.dart";

/// A complete immutable observation, paired with the catalog that interprets it.
///
/// Display queries use this value without collecting save expectations.
/// Unfinished authored values survive every working publication.
/// Relation indexes by document identity. A document is immutable, so its
/// index never goes stale.
final _relationIndexes = Expando<AuthoringRelationIndex>();

@freezed
abstract class AuthoringDocument
    with _$AuthoringDocument
    implements PortableAuthoringView {
  const factory AuthoringDocument({
    required CheckedEditorCatalog catalog,
    required Map<skir.ResourceId, skir.AuthoringResource> entries,
    required List<skir.LinkProjection> links,
    @Default(0) int revision,
    skir.AuthoringObservationId? confirmedObservation,
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
      confirmedObservation: state.confirmedObservation,
      entries: Map.unmodifiable({
        for (final entry in state.resources) entry.id: entry,
      }),
      links: List.unmodifiable(state.links),
    );
  }

  /// The ownership index of this document, derived once per document.
  AuthoringRelationIndex get relations =>
      _relationIndexes[this] ??= AuthoringRelationIndex.fromDocument(this);

  @override
  skir.CatalogGeneration get generation => catalog.snapshot.generation;
  skir.AuthoringResource? entry(skir.ResourceId id) => entries[id];

  /// Exactly what the realm stores for [id]: fields its resource leaves unset
  /// are absent. Edits, admission and inputs that tell set from unset read it.
  skir.AuthoringRecord? storedResource(skir.ResourceId id) =>
      entries[id]?.content;

  /// The content of [id] as a reader sees it: each field its resource leaves
  /// unset holds what the realm said it reads as.
  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => switch (entries[id]) {
    final entry? => entry.read,
    null => null,
  };

  @override
  Map<skir.ResourceId, skir.AuthoringRecord> get resources => Map.unmodifiable({
    for (final entry in entries.entries) entry.key: entry.value.read,
  });
  @override
  skir.DataValue defaultValue(skir.TypeUse? type) =>
      _AuthoringDefaults(catalog).forType(type);

  /// What the value at [location] reads as while it is or lies below a field
  /// its resource leaves unset, as the realm last said; null for a stored or
  /// unknown value.
  skir.DataValue? unsetValue(skir.ValueLocation location) {
    final record = storedResource(location.resource);
    final segments = location.path.segments.toList(growable: false);
    for (final unset
        in entries[location.resource]?.unset ?? const <skir.UnsetValue>[]) {
      final prefix = unset.path.segments.toList(growable: false);
      if (prefix.length > segments.length) continue;
      if (!_startsWith(segments, prefix)) continue;
      if (record?.readAt(unset.path) is PortablePathValue) return null;
      if (prefix.length == segments.length) return unset.value;
      return switch (unset.value.readAt(
        skir.ValuePath(segments: segments.skip(prefix.length)),
      )) {
        PortablePathValue(:final value) => value,
        _ => null,
      };
    }
    return null;
  }

  /// The value at [location] as a reader sees it, unset fields included.
  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) =>
      resource(location.resource)?.readAt(location.path) ??
      const PortablePathUnavailable("The resource is absent");
}

final _readRecords = Expando<skir.AuthoringRecord>("read records");

extension on skir.AuthoringResource {
  /// Its content as a reader sees it, derived once per resource.
  skir.AuthoringRecord get read =>
      _readRecords[this] ??= content.withUnset(unset);
}

extension on skir.AuthoringRecord {
  /// This record with each field of [unset] it does not store holding the
  /// value the realm said it reads as.
  skir.AuthoringRecord withUnset(Iterable<skir.UnsetValue> unset) {
    var read = this;
    for (final field in unset) {
      if (read.readAt(field.path) is PortablePathValue) continue;
      if (read.replaceAt(field.path, field.value) case PortablePathValue(
        :final value,
      )) {
        read = value;
      }
    }
    return read;
  }
}

bool _startsWith(List<skir.PathSegment> path, List<skir.PathSegment> prefix) {
  for (var index = 0; index < prefix.length; index++) {
    if (path[index] != prefix[index]) return false;
  }
  return true;
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
