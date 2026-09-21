// The page catalog is the realm supplied registry for page kinds and their
// editor contracts. Definitions carry artifact provenance so invalid page
// declarations can be reported without losing valid page kinds.
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_page_catalog.freezed.dart";

@freezed
/// Stable page kind identity paired with the revision of its contract.
abstract class PageKindRef with _$PageKindRef {
  const factory PageKindRef({required String id, required int revision}) =
      _PageKindRef;

  const PageKindRef._();

  factory PageKindRef.fromSkir(skir.PageKindRef value) =>
      PageKindRef(id: value.id.value, revision: value.revision);

  skir.PageKindRef toSkir() => skir.PageKindRef(
    id: skir.PageKindId(value: id),
    revision: revision,
  );
}

@freezed
/// Editor shape and accepted type references for a page kind.
sealed class RealmPageEditor with _$RealmPageEditor {
  const factory RealmPageEditor.graph({
    required GraphDirection direction,
    required List<ResolvedTypeRef> nodeTypes,
  }) = RealmGraphPageEditor;

  const factory RealmPageEditor.timeline({
    required List<ResolvedTypeRef> trackTypes,
    required List<ResolvedTypeRef> segmentTypes,
    required List<ResolvedTypeRef> keyframeTypes,
  }) = RealmTimelinePageEditor;
}

/// Open page rule identity published by Realm for local explanation and preview.
final class RealmPageAuthoringRuleRef {
  const RealmPageAuthoringRuleRef({
    required this.id,
    required this.revision,
    this.configuration,
  });

  final String id;
  final int revision;
  final skir.TypedValueEnvelope? configuration;
}

@freezed
/// Realm supplied page kind metadata used to choose and configure an editor.
abstract class RealmPageDefinition with _$RealmPageDefinition {
  const factory RealmPageDefinition({
    required PageKindRef kind,
    required String name,
    required String? description,
    required IconValue icon,
    required Color color,
    required RealmPageEditor editor,
    required TypedCatalogPresentationSubject presentationSubject,
    required String originArtifactId,
    required String sourcePart,
    @Default([]) List<RealmPageAuthoringRuleRef> authoringRules,
  }) = _RealmPageDefinition;

  const RealmPageDefinition._();

  String get id => "page_kind:${kind.id}:${kind.revision}";
}

@freezed
/// Diagnostic for a page declaration that could not enter the catalog.
abstract class RealmPageDiagnostic with _$RealmPageDiagnostic {
  const factory RealmPageDiagnostic({
    required String code,
    required String message,
    required String? originArtifactId,
    required String? sourcePart,
    required String? declarationName,
    required PageKindRef? kind,
  }) = _RealmPageDiagnostic;
}

@freezed
/// All valid page definitions and declaration diagnostics for one realm catalog.
abstract class RealmPageCatalog with _$RealmPageCatalog {
  const factory RealmPageCatalog({
    @Default({}) Map<PageKindRef, RealmPageDefinition> definitions,
    @Default([]) List<RealmPageDiagnostic> diagnostics,
  }) = _RealmPageCatalog;
}
