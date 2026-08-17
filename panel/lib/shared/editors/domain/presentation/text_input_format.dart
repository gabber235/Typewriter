import "package:freezed_annotation/freezed_annotation.dart";

part "text_input_format.freezed.dart";

@freezed
sealed class TextInputFormat with _$TextInputFormat {
  const factory TextInputFormat.lowercase() = LowercaseTextInputFormat;

  const factory TextInputFormat.uppercase() = UppercaseTextInputFormat;

  const factory TextInputFormat.replace({
    required String pattern,
    required String replacement,
  }) = ReplaceTextInputFormat;

  const factory TextInputFormat.allow(String pattern) = AllowTextInputFormat;

  const factory TextInputFormat.deny(String pattern) = DenyTextInputFormat;
}
