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
abstract class RealmActionId with _$RealmActionId {
  @Assert("namespace != \"\"", "Namespace must not be empty.")
  @Assert("name != \"\"", "Name must not be empty.")
  const factory RealmActionId({
    required String namespace,
    required String name,
  }) = _RealmActionId;
}

@freezed
abstract class CatalogGeneration with _$CatalogGeneration {
  @Assert("value != \"\"", "Generation must not be empty.")
  const factory CatalogGeneration(String value) = _CatalogGeneration;
}
