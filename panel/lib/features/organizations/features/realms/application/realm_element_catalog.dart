import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_element_catalog.freezed.dart";

@freezed
sealed class ElementAvailability with _$ElementAvailability {
  const factory ElementAvailability.always() = ElementAlwaysAvailable;

  const factory ElementAvailability.fact({
    required String key,
    required String expected,
  }) = ElementFactAvailability;

  const factory ElementAvailability.all(List<ElementAvailability> expressions) =
      ElementAllAvailability;

  const factory ElementAvailability.any(List<ElementAvailability> expressions) =
      ElementAnyAvailability;

  const factory ElementAvailability.not(ElementAvailability expression) =
      ElementNotAvailability;
}

@freezed
abstract class DiscoveredElementDefinition with _$DiscoveredElementDefinition {
  const factory DiscoveredElementDefinition({
    required String id,
    required ResolvedTypeRef type,
    required String name,
    required String description,
    required IconValue icon,
    required Color color,
    required ElementAvailability availability,
  }) = _DiscoveredElementDefinition;
}

@freezed
abstract class RealmElementCatalogEntry with _$RealmElementCatalogEntry {
  const factory RealmElementCatalogEntry({
    required String originArtifactId,
    required String sourcePart,
    required DiscoveredElementDefinition definition,
    required bool eligible,
    required bool available,
    @Default([]) List<String> ineligibilityReasons,
  }) = _RealmElementCatalogEntry;
}
