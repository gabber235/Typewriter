part of "authoring_session.dart";

@freezed
abstract class AuthoringSessionState with _$AuthoringSessionState {
  const factory AuthoringSessionState({
    skir.AuthoringState? snapshot,
    CheckedEditorCatalog? catalog,
    @Default(false) bool refreshing,
    Object? failure,
  }) = _AuthoringSessionState;
}

extension AuthoringStateView on AuthoringSessionState {
  skir.CatalogGeneration? get generation => snapshot?.generation;

  Map<skir.ResourceId, skir.AuthoringResource> get resources => {
    for (final resource
        in snapshot?.resources.toList(growable: false) ??
            const <skir.AuthoringResource>[])
      resource.id: resource,
  };

  List<skir.LinkProjection> get links =>
      snapshot?.links.toList(growable: false) ?? const [];

  List<skir.FindingSet> get findings =>
      snapshot?.findings.toList(growable: false) ?? const [];

  AuthoringDocument? get confirmedDocument {
    final source = snapshot;
    final checked = catalog;
    if (source == null ||
        checked == null ||
        source.generation != checked.snapshot.generation) {
      return null;
    }
    return AuthoringDocument.fromState(source, catalog: checked);
  }
}
