import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_type_entry.freezed.dart";

/// Editor layout attached to an exact concrete type.
@freezed
sealed class RealmEditorLayout with _$RealmEditorLayout {
  const factory RealmEditorLayout.graph({required GraphDirection direction}) =
      RealmGraphEditorLayout;

  const factory RealmEditorLayout.timeline() = RealmTimelineEditorLayout;
}

/// Structural definition and optional authoring metadata from one Realm generation.
@freezed
abstract class RealmTypeEntry with _$RealmTypeEntry {
  const factory RealmTypeEntry({
    required TypeDefinition definition,
    required bool eligible,
    @Default([]) List<String> ineligibilityReasons,
    String? description,
    IconValue? icon,
    Color? color,
    RealmEditorLayout? editor,
    TypedCatalogPresentationSubject? presentationSubject,
  }) = _RealmTypeEntry;

  const RealmTypeEntry._();

  ResolvedTypeRef get type => definition.id;
  String get name => definition.displayName ?? definition.id.toString();
  String get id => type.toString();
}
