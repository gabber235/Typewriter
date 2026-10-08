import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_definition.freezed.dart";

/// Whether a conversion preserves the source value's meaning.
enum ConversionSafety {
  /// The conversion is eligible for implicit editor use.
  lossless,

  /// The conversion requires an explicit choice by the caller.
  lossy,
}

/// Where a conversion executes relative to the panel.
enum ConversionLocality {
  /// The panel can evaluate the rule without a realm request.
  local,

  /// The realm must execute the conversion; the panel can only describe it.
  realm,
}

/// Catalog metadata for one typed edge in the conversion graph.
///
/// The graph uses [source], [target], [cost], and the safety metadata for path
/// selection. [rule] supplies the value transformation after selection.
/// [fallible] records that application can produce diagnostics, while
/// [locality] determines whether the panel can apply it or must report it as
/// unavailable. The constructor rejects negative costs.
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
