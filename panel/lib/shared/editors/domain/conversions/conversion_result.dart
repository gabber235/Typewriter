import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_result.freezed.dart";

@freezed
sealed class ConversionResult with _$ConversionResult {
  const factory ConversionResult.success(DataValue value) = ConversionSuccess;
  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  factory ConversionResult.failure(List<TypeDiagnostic> diagnostics) =
      ConversionFailure;
  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  factory ConversionResult.unavailable(List<TypeDiagnostic> diagnostics) =
      ConversionUnavailable;
}
