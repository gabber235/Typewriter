import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_definition.freezed.dart";

enum ConversionSafety { lossless, lossy }

enum ConversionLocality { local, realm }

@freezed
abstract class ConversionDefinition with _$ConversionDefinition {
  @Assert("cost >= 0", "Cost must not be negative.")
  const factory ConversionDefinition({
    required ConversionId id,
    required ResolvedTypeRef source,
    required ResolvedTypeRef target,
    required ConversionRule rule,
    @Default(ConversionSafety.lossless) ConversionSafety safety,
    @Default(false) bool fallible,
    @Default(ConversionLocality.local) ConversionLocality locality,
    @Default(1) int cost,
  }) = _ConversionDefinition;
}
