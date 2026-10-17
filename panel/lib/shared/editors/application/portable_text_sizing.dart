import "package:typewriter_panel/typewriter_panel.dart";

part "portable_text_sizing.freezed.dart";

/// Validated logical font sizes resolved from portable text expressions.
@freezed
sealed class ResolvedTextSizing with _$ResolvedTextSizing {
  const factory ResolvedTextSizing.exact(double size) = ExactTextSizing;
  const factory ResolvedTextSizing.fit({
    required double minimum,
    required double maximum,
  }) = FitTextSizing;
}
