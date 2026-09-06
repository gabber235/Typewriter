import "package:freezed_annotation/freezed_annotation.dart";

part "catalog_id.freezed.dart";

@freezed
abstract class PresentationId with _$PresentationId {
  @Assert("namespace != \"\"", "Namespace must not be empty.")
  @Assert("name != \"\"", "Name must not be empty.")
  const factory PresentationId({
    required String namespace,
    required String name,
  }) = _PresentationId;
}

@freezed
abstract class ConversionId with _$ConversionId {
  @Assert("namespace != \"\"", "Namespace must not be empty.")
  @Assert("name != \"\"", "Name must not be empty.")
  const factory ConversionId({
    required String namespace,
    required String name,
  }) = _ConversionId;
}

@freezed
abstract class CapabilityId with _$CapabilityId {
  @Assert("value != \"\"", "Capability ID must not be empty.")
  const factory CapabilityId(String value) = _CapabilityId;
}

@freezed
abstract class CatalogGeneration with _$CatalogGeneration {
  @Assert("value != \"\"", "Generation must not be empty.")
  const factory CatalogGeneration(String value) = _CatalogGeneration;
}
