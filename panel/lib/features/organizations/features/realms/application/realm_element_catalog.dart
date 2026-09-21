// These models preserve discovery metadata from the realm catalog. Eligibility
// answers whether the panel may offer an element, while availability records
// whether the realm currently exposes it. Keeping both lets the UI explain why
// a discovered definition is absent without inventing local policy.
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_element_catalog.freezed.dart";

@freezed
/// Realm supplied expression describing when an element is available to users.
/// It is data for consumers to interpret, not a second local availability
/// authority.
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
/// Display and type metadata for an element discovered from a realm artifact.
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
/// Discovery record retaining provenance, eligibility, and current availability.
/// Ineligible or unavailable entries remain observable for diagnostics but are
/// filtered before creation controls are built.
abstract class RealmElementCatalogEntry with _$RealmElementCatalogEntry {
  const factory RealmElementCatalogEntry({
    required String originArtifactId,
    required String sourcePart,
    required DiscoveredElementDefinition definition,
    required TypedCatalogPresentationSubject presentationSubject,
    required bool eligible,
    required bool available,
    @Default([]) List<String> ineligibilityReasons,
  }) = _RealmElementCatalogEntry;
}
