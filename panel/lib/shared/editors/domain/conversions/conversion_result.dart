import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_result.freezed.dart";

/// Outcome of applying a conversion rule or selected graph path.
///
/// Callers must distinguish a rejected value from unavailable execution.
/// Failure means the supplied value or rule could not produce the target;
/// unavailable means the operation belongs to another execution boundary,
/// such as a realm. Both non success variants retain diagnostics for recovery
/// or presentation.
@freezed
sealed class ConversionResult with _$ConversionResult {
  /// The conversion produced [value].
  const factory ConversionResult.success(DataValue value) = ConversionSuccess;
  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  /// The input was rejected or the conversion could not produce a value.
  factory ConversionResult.failure(List<TypeDiagnostic> diagnostics) =
      ConversionFailure;
  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  /// Local execution is not responsible for this conversion.
  factory ConversionResult.unavailable(List<TypeDiagnostic> diagnostics) =
      ConversionUnavailable;
}
