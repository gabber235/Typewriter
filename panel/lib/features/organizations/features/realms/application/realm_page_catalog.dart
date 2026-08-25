import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/page_kind.dart"
    as wire_page_kind;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_page_catalog.freezed.dart";

@freezed
abstract class PageKindRef with _$PageKindRef {
  const factory PageKindRef({required String id, required int revision}) =
      _PageKindRef;

  const PageKindRef._();

  factory PageKindRef.fromSkir(wire_page_kind.PageKindRef value) =>
      PageKindRef(id: value.id.value, revision: value.revision);

  wire_page_kind.PageKindRef toSkir() => wire_page_kind.PageKindRef(
    id: wire_page_kind.PageKindId(value: id),
    revision: revision,
  );
}

@freezed
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

@freezed
abstract class RealmPageDefinition with _$RealmPageDefinition {
  const factory RealmPageDefinition({
    required PageKindRef kind,
    required String name,
    required String? description,
    required IconValue icon,
    required Color color,
    required RealmPageEditor editor,
    required String originArtifactId,
    required String sourcePart,
  }) = _RealmPageDefinition;
}

@freezed
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
abstract class RealmPageCatalog with _$RealmPageCatalog {
  const factory RealmPageCatalog({
    @Default({}) Map<PageKindRef, RealmPageDefinition> definitions,
    @Default([]) List<RealmPageDiagnostic> diagnostics,
  }) = _RealmPageCatalog;
}
