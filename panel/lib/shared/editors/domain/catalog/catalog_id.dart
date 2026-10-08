import "package:typewriter_panel/typewriter_panel.dart";

part "catalog_id.freezed.dart";

/// Stable catalog identity for a presentation definition.
///
/// [namespace] separates producers, and [name] identifies the definition
/// within that namespace. Both components are required for wire lookup.
@freezed
abstract class PresentationId with _$PresentationId {
  @Assert("namespace != \"\"", "Namespace must not be empty.")
  @Assert("name != \"\"", "Name must not be empty.")
  const factory PresentationId({
    required String namespace,
    required String name,
  }) = _PresentationId;
}

/// Stable identity used to reference a conversion across catalog boundaries.
///
/// Conversion rules embedded in another rule have no identity, so this type is
/// reserved for definitions and references that providers can resolve.
@freezed
abstract class ConversionId with _$ConversionId {
  @Assert("namespace != \"\"", "Namespace must not be empty.")
  @Assert("name != \"\"", "Name must not be empty.")
  const factory ConversionId({
    required String namespace,
    required String name,
  }) = _ConversionId;
}

/// Stable key for a catalog capability exposed by an editor provider.
///
/// The value is opaque to this domain. Its producer and consumers must agree
/// on its meaning through the surrounding catalog contract.
@freezed
abstract class CapabilityId with _$CapabilityId {
  @Assert("value != \"\"", "Capability ID must not be empty.")
  const factory CapabilityId(String value) = _CapabilityId;
}

/// Opaque revision of a catalog used to correlate requests with its snapshot.
///
/// Generation comparison belongs to the provider that publishes the catalog;
/// this value only prevents an empty generation from entering the domain.
@freezed
abstract class CatalogGeneration with _$CatalogGeneration {
  @Assert("value != \"\"", "Generation must not be empty.")
  const factory CatalogGeneration(String value) = _CatalogGeneration;
}
