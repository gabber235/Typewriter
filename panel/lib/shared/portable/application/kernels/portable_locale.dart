import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

// Locale resolution for the panel profile operations. A locale argument must
// be a well formed BCP 47 language tag; anything else fails invalid_locale. A
// well formed tag resolves to the most specific CLDR data intl ships, falling
// back from region to language and finally to the root locale `und`, which
// every operation defines without locale data.

final _languageTag = RegExp(
  "^[A-Za-z]{2,8}(?:-[A-Za-z]{4})?(?:-(?:[A-Za-z]{2}|[0-9]{3}))?"
  "(?:-(?:[A-Za-z0-9]{5,8}|[0-9][A-Za-z0-9]{3}))*"
  "(?:-[0-9A-WY-Za-wy-z](?:-[A-Za-z0-9]{2,8})+)*"
  r"(?:-[xX](?:-[A-Za-z0-9]{1,8})+)?$",
);

/// The intl locale name with data [exists] for the BCP 47 [tag], or null for
/// the root locale. A malformed tag fails `invalid_locale`.
String? resolvePortableLocale(String tag, bool Function(String name) exists) {
  if (!_languageTag.hasMatch(tag)) {
    throw skir.PortableOperationFailure(
      skir.PortableFailures.invalidLocale,
      "The locale $tag is not a BCP 47 language tag.",
    );
  }
  final subtags = tag.split("-");
  if (subtags.first.toLowerCase() == "und") return null;
  for (var length = subtags.length; length > 0; length--) {
    final candidate = Intl.canonicalizedLocale(subtags.take(length).join("_"));
    if (exists(candidate)) return candidate;
  }
  return null;
}
