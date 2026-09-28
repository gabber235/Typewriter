// The page catalog maps concrete Page types to their editor layouts.
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_page_catalog.freezed.dart";

@freezed
/// Editor layout for a concrete Page type.
sealed class RealmPageEditor with _$RealmPageEditor {
  const factory RealmPageEditor.graph({
    required GraphDirection direction,
  }) = RealmGraphPageEditor;

  const factory RealmPageEditor.timeline() = RealmTimelinePageEditor;
}

@freezed
/// Realm supplied metadata for a concrete Page type.
abstract class RealmPageDefinition with _$RealmPageDefinition {
  const factory RealmPageDefinition({
    required ResolvedTypeRef type,
    required String name,
    required String? description,
    required IconValue icon,
    required Color color,
    required RealmPageEditor editor,
    required TypedCatalogPresentationSubject presentationSubject,
    required String originArtifactId,
    required String sourcePart,
  }) = _RealmPageDefinition;

  const RealmPageDefinition._();

  String get id => "page:$type";
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
    required ResolvedTypeRef? type,
  }) = _RealmPageDiagnostic;
}

@freezed
/// All valid page definitions and declaration diagnostics for one realm catalog.
abstract class RealmPageCatalog with _$RealmPageCatalog {
  const factory RealmPageCatalog({
    @Default({}) Map<ResolvedTypeRef, RealmPageDefinition> definitions,
    @Default([]) List<RealmPageDiagnostic> diagnostics,
  }) = _RealmPageCatalog;
}
