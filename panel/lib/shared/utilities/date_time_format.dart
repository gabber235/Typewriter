const _dateTimePatternLetters = "GyQqMLwWdDFgEecabBhHKkjJmsSAzZOvVXx";

String? dateTimePatternError(String pattern) {
  var quoted = false;
  for (var index = 0; index < pattern.length; index++) {
    final character = pattern[index];
    if (character == "'") {
      if (index + 1 < pattern.length && pattern[index + 1] == "'") {
        index++;
      } else {
        quoted = !quoted;
      }
      continue;
    }
    final code = character.codeUnitAt(0);
    final letter = code >= 65 && code <= 90 || code >= 97 && code <= 122;
    if (!quoted && letter && !_dateTimePatternLetters.contains(character)) {
      return "Unsupported date time pattern letter: $character";
    }
  }
  return quoted ? "Date time pattern contains an unmatched quote" : null;
}
