import "package:typewriter_panel/typewriter_panel.dart";

/// Text roles the Material [TextTheme] has no slot for.
///
/// A full sentence (an empty state, an error, a heading description, a
/// field message) uses [sentence] or [sentenceSmall]. Labels, names, values
/// and buttons stay on the Material roles.
@immutable
class TypewriterText extends ThemeExtension<TypewriterText> {
  const TypewriterText({required this.sentence, required this.sentenceSmall});

  /// A sentence in body size: IBM Plex Sans 14/20.
  final TextStyle sentence;

  /// A sentence beside or under a control: IBM Plex Sans 12/16.
  final TextStyle sentenceSmall;

  @override
  TypewriterText copyWith({TextStyle? sentence, TextStyle? sentenceSmall}) =>
      TypewriterText(
        sentence: sentence ?? this.sentence,
        sentenceSmall: sentenceSmall ?? this.sentenceSmall,
      );

  @override
  TypewriterText lerp(covariant TypewriterText? other, double t) {
    if (other == null) return this;
    return TypewriterText(
      sentence: TextStyle.lerp(sentence, other.sentence, t)!,
      sentenceSmall: TextStyle.lerp(sentenceSmall, other.sentenceSmall, t)!,
    );
  }
}
