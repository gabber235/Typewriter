import "dart:collection";

sealed class PortableRegexNormalization {
  const PortableRegexNormalization();
}

final class PortableRegexReady extends PortableRegexNormalization {
  const PortableRegexReady(this.pattern);

  final String pattern;
}

final class PortableRegexInvalid extends PortableRegexNormalization {
  const PortableRegexInvalid(this.reason);

  final String reason;
}

final class PortableRegexUnsupported extends PortableRegexNormalization {
  const PortableRegexUnsupported(this.reason);

  final String reason;
}

extension PortableRegexString on String {
  PortableRegexNormalization normalizePortableRegex() {
    final pattern = this;
    if (pattern.length > 512) {
      return const PortableRegexUnsupported(
        "The regular expression pattern exceeds its limit",
      );
    }
    final output = StringBuffer();
    var index = 0;
    var groupDepth = 0;
    var groupCount = 0;
    var lastAtom = _RegexAtom.none;
    var currentAtomQuantified = false;
    var priorAtomQuantified = false;

    void beginAtom() {
      priorAtomQuantified = currentAtomQuantified;
      currentAtomQuantified = false;
      lastAtom = _RegexAtom.value;
    }

    while (index < pattern.length) {
      final character = pattern[index];
      switch (character) {
        case r"\":
          beginAtom();
          final escape = _normalizeEscape(pattern, index + 1, false);
          switch (escape) {
            case _EscapeReady(:final value, :final lastIndex):
              output.write(value);
              index = lastIndex;
            case _EscapeInvalid(:final reason):
              return PortableRegexInvalid(reason);
            case _EscapeUnsupported(:final reason):
              return PortableRegexUnsupported(reason);
          }
        case "[":
          beginAtom();
          final characterClass = _normalizeCharacterClass(pattern, index + 1);
          switch (characterClass) {
            case _CharacterClassReady(:final value, :final lastIndex):
              output.write(value);
              index = lastIndex;
            case _CharacterClassInvalid(:final reason):
              return PortableRegexInvalid(reason);
            case _CharacterClassUnsupported(:final reason):
              return PortableRegexUnsupported(reason);
          }
        case "(":
          if (index + 1 < pattern.length && pattern[index + 1] == "?") {
            return const PortableRegexUnsupported(
              "Lookarounds, named groups, flags, and special groups are not supported",
            );
          }
          groupDepth++;
          groupCount++;
          if (groupDepth > 16 || groupCount > 32) {
            return const PortableRegexUnsupported(
              "The regular expression contains too many groups",
            );
          }
          priorAtomQuantified = false;
          currentAtomQuantified = false;
          lastAtom = _RegexAtom.none;
          output.write(character);
        case ")":
          if (groupDepth == 0) {
            return const PortableRegexInvalid(
              "The regular expression contains an unmatched closing group",
            );
          }
          groupDepth--;
          priorAtomQuantified = currentAtomQuantified;
          currentAtomQuantified = false;
          lastAtom = _RegexAtom.group;
          output.write(character);
        case "*" || "+" || "?":
          if (lastAtom == _RegexAtom.none) {
            return const PortableRegexInvalid(
              "The regular expression contains a quantifier without an atom",
            );
          }
          if (lastAtom == _RegexAtom.anchor) {
            return const PortableRegexInvalid(
              "A regular expression anchor cannot be quantified",
            );
          }
          if (lastAtom == _RegexAtom.group) {
            return const PortableRegexUnsupported(
              "Repeating a group is not supported by portable regular expressions",
            );
          }
          if (currentAtomQuantified || priorAtomQuantified) {
            return const PortableRegexUnsupported(
              "Adjacent, lazy, and possessive quantifiers are not supported",
            );
          }
          currentAtomQuantified = true;
          output.write(character);
        case "{":
          if (lastAtom == _RegexAtom.none) {
            return const PortableRegexInvalid(
              "The regular expression contains a quantifier without an atom",
            );
          }
          if (lastAtom == _RegexAtom.anchor) {
            return const PortableRegexInvalid(
              "A regular expression anchor cannot be quantified",
            );
          }
          if (lastAtom == _RegexAtom.group) {
            return const PortableRegexUnsupported(
              "Repeating a group is not supported by portable regular expressions",
            );
          }
          if (currentAtomQuantified || priorAtomQuantified) {
            return const PortableRegexUnsupported(
              "Adjacent quantifiers are not supported",
            );
          }
          final end = pattern.indexOf("}", index + 1);
          if (end < 0) {
            return const PortableRegexInvalid(
              "The regular expression contains an unterminated repetition",
            );
          }
          final bounds = pattern.substring(index + 1, end).split(",");
          if (bounds.isEmpty ||
              bounds.length > 2 ||
              bounds.any(
                (bound) => bound.isNotEmpty && !bound.split("").every(_isDigit),
              )) {
            return const PortableRegexInvalid(
              "The regular expression contains an invalid repetition",
            );
          }
          final values = bounds
              .where((bound) => bound.isNotEmpty)
              .map(int.tryParse);
          if (values.any((value) => value == null || value > 1000)) {
            return const PortableRegexUnsupported(
              "The regular expression repetition exceeds its limit",
            );
          }
          if (bounds.length == 2 && bounds[1].isNotEmpty) {
            final minimum = int.tryParse(bounds[0]);
            final maximum = int.tryParse(bounds[1]);
            if (minimum == null || maximum == null) {
              return const PortableRegexInvalid(
                "The regular expression repetition is invalid",
              );
            }
            if (minimum > maximum) {
              return const PortableRegexInvalid(
                "The regular expression repetition range is reversed",
              );
            }
          }
          currentAtomQuantified = true;
          output.write(pattern.substring(index, end + 1));
          index = end;
        case "|":
          priorAtomQuantified = false;
          currentAtomQuantified = false;
          lastAtom = _RegexAtom.none;
          output.write(character);
        case ".":
          beginAtom();
          output.write(_portableDot);
        case "^" || r"$":
          priorAtomQuantified = false;
          currentAtomQuantified = false;
          lastAtom = _RegexAtom.anchor;
          output.write(character);
        default:
          beginAtom();
          output.write(character);
      }
      index++;
    }
    if (groupDepth != 0) {
      return const PortableRegexInvalid(
        "The regular expression contains an unterminated group",
      );
    }
    return PortableRegexReady(output.toString());
  }
}

sealed class _EscapeNormalization {
  const _EscapeNormalization();
}

final class _EscapeReady extends _EscapeNormalization {
  const _EscapeReady(this.value, this.lastIndex);

  final String value;
  final int lastIndex;
}

final class _EscapeInvalid extends _EscapeNormalization {
  const _EscapeInvalid(this.reason);

  final String reason;
}

final class _EscapeUnsupported extends _EscapeNormalization {
  const _EscapeUnsupported(this.reason);

  final String reason;
}

_EscapeNormalization _normalizeEscape(
  String pattern,
  int escapedIndex,
  bool inCharacterClass,
) {
  if (escapedIndex >= pattern.length) {
    return const _EscapeInvalid(
      "The regular expression ends with an incomplete escape",
    );
  }
  final escaped = pattern[escapedIndex];
  if (_isDigit(escaped) && escaped != "0") {
    return const _EscapeUnsupported(
      "Backreferences are not supported by portable regular expressions",
    );
  }
  if ("QEpPkKgGNXRLCvVbB".contains(escaped)) {
    return const _EscapeUnsupported(
      "The regular expression uses a host specific escape",
    );
  }
  if (inCharacterClass && "DSW".contains(escaped)) {
    return const _EscapeUnsupported(
      "Complement shorthand escapes inside character classes are not supported by portable regular expressions",
    );
  }
  return switch (escaped) {
    "d" => _EscapeReady(
      inCharacterClass ? _asciiDigits : "[$_asciiDigits]",
      escapedIndex,
    ),
    "D" => _EscapeReady("[^$_asciiDigits]", escapedIndex),
    "s" => _EscapeReady(
      inCharacterClass ? _portableWhitespace : "[$_portableWhitespace]",
      escapedIndex,
    ),
    "S" => _EscapeReady("[^$_portableWhitespace]", escapedIndex),
    "w" => _EscapeReady(
      inCharacterClass ? _asciiWord : "[$_asciiWord]",
      escapedIndex,
    ),
    "W" => _EscapeReady("[^$_asciiWord]", escapedIndex),
    "0" => _EscapeReady(r"\x00", escapedIndex),
    "x" => _normalizeFixedHexEscape(pattern, escapedIndex, 2),
    "u" => _normalizeFixedHexEscape(pattern, escapedIndex, 4),
    _ when _portableLiteralEscapes.contains(escaped) => _EscapeReady(
      "\\$escaped",
      escapedIndex,
    ),
    _ => const _EscapeUnsupported(
      "The regular expression uses an unsupported escape",
    ),
  };
}

_EscapeNormalization _normalizeFixedHexEscape(
  String pattern,
  int markerIndex,
  int digits,
) {
  final end = markerIndex + digits + 1;
  if (end > pattern.length ||
      !_isHexSequence(pattern, markerIndex + 1, digits)) {
    return _EscapeInvalid(
      digits == 2
          ? "A hexadecimal escape must contain exactly two digits"
          : "A Unicode escape must contain exactly four digits",
    );
  }
  final value = int.parse(pattern.substring(markerIndex + 1, end), radix: 16);
  if (digits == 4 && value >= 0xd800 && value <= 0xdfff) {
    return const _EscapeUnsupported(
      "Surrogate code unit escapes are not supported by portable regular expressions",
    );
  }
  return _EscapeReady(pattern.substring(markerIndex - 1, end), end - 1);
}

sealed class _CharacterClassNormalization {
  const _CharacterClassNormalization();
}

final class _CharacterClassReady extends _CharacterClassNormalization {
  const _CharacterClassReady(this.value, this.lastIndex);

  final String value;
  final int lastIndex;
}

final class _CharacterClassInvalid extends _CharacterClassNormalization {
  const _CharacterClassInvalid(this.reason);

  final String reason;
}

final class _CharacterClassUnsupported extends _CharacterClassNormalization {
  const _CharacterClassUnsupported(this.reason);

  final String reason;
}

_CharacterClassNormalization _normalizeCharacterClass(
  String pattern,
  int start,
) {
  final output = StringBuffer("[");
  var index = start;
  if (index < pattern.length && pattern[index] == "^") {
    output.write("^");
    index++;
  }
  var hasAtom = false;
  while (index < pattern.length) {
    final character = pattern[index];
    switch (character) {
      case "]":
        if (!hasAtom) {
          return const _CharacterClassInvalid(
            "The regular expression contains an empty character class",
          );
        }
        output.write("]");
        return _CharacterClassReady(output.toString(), index);
      case r"\":
        final escape = _normalizeEscape(pattern, index + 1, true);
        switch (escape) {
          case _EscapeReady(:final value, :final lastIndex):
            output.write(value);
            index = lastIndex;
            hasAtom = true;
          case _EscapeInvalid(:final reason):
            return _CharacterClassInvalid(reason);
          case _EscapeUnsupported(:final reason):
            return _CharacterClassUnsupported(reason);
        }
      case "&":
        if (index + 1 < pattern.length && pattern[index + 1] == "&") {
          return const _CharacterClassUnsupported(
            "Character class intersection and subtraction are not supported",
          );
        }
        output.write(character);
        hasAtom = true;
      case "-":
        if (index + 1 < pattern.length && pattern[index + 1] == "-") {
          return const _CharacterClassUnsupported(
            "Character class intersection and subtraction are not supported",
          );
        }
        output.write(character);
        hasAtom = true;
      case "[":
        return const _CharacterClassUnsupported(
          "Nested character classes are not supported",
        );
      default:
        output.write(character);
        hasAtom = true;
    }
    index++;
  }
  return const _CharacterClassInvalid(
    "The regular expression contains an unterminated character class",
  );
}

enum _RegexAtom { none, value, group, anchor }

bool _isDigit(String value) {
  final unit = value.codeUnitAt(0);
  return unit >= 48 && unit <= 57;
}

bool _isHexSequence(String source, int start, int length) {
  for (var index = start; index < start + length; index++) {
    final unit = source.codeUnitAt(index);
    final digit = unit >= 48 && unit <= 57;
    final lower = unit >= 97 && unit <= 102;
    final upper = unit >= 65 && unit <= 70;
    if (!digit && !lower && !upper) return false;
  }
  return true;
}

const _asciiDigits = "0-9";
const _asciiWord = "A-Za-z0-9_";
const _portableWhitespace =
    r"\x09-\x0D\x20\x85\xA0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\uFEFF";
const _portableDot = r"[^\n\r\u2028\u2029]";
const _portableLiteralEscapes = r"fnrt\.*+?^${}()|[]/-";

final class PortableRegexMatcher {
  PortableRegexMatcher._(this._instructions, this._start, this.groupCount);

  factory PortableRegexMatcher.compile(String pattern) {
    final parser = _PortableRegexParser(pattern);
    final parsed = parser.parse();
    final program = _PortableRegexCompiler(2048).finish(parsed);
    return PortableRegexMatcher._(
      program.instructions,
      program.start,
      parser.groupCount,
    );
  }

  final List<_RegexInstruction> _instructions;
  final int _start;
  final int groupCount;

  bool containsMatchIn(String input, void Function() consumeStep) =>
      find(input, consumeStep) != null;

  bool matches(String input, void Function() consumeStep) {
    final codePoints = input.runes.toList(growable: false);
    final captures = List<int>.filled((groupCount + 1) * 2, _unsetCapture);
    var current = _closure(
      [_MachineThread(_start, captures)],
      0,
      codePoints.length,
      consumeStep,
    );
    for (var index = 0; index < codePoints.length; index++) {
      current = _advance(
        current,
        codePoints[index],
        index + 1,
        codePoints.length,
        consumeStep,
      );
    }
    return current.any(
      (thread) =>
          _instructions[thread.instruction].kind == _InstructionKind.match,
    );
  }

  PortableRegexMatch? find(String input, void Function() consumeStep) =>
      _find(input.runes.toList(growable: false), 0, consumeStep);

  String replace(
    String input,
    String replacement,
    void Function() consumeStep,
  ) {
    final codePoints = input.runes.toList(growable: false);
    final output = StringBuffer();
    var copiedUntil = 0;
    var searchFrom = 0;
    while (searchFrom <= codePoints.length) {
      final match = _find(codePoints, searchFrom, consumeStep);
      if (match == null) break;
      _appendCodePoints(
        output,
        codePoints,
        copiedUntil,
        match.start,
        consumeStep,
      );
      _appendReplacement(
        output,
        replacement,
        codePoints,
        match.captures,
        groupCount,
        consumeStep,
      );
      copiedUntil = match.end;
      searchFrom = match.start == match.end
          ? (match.end == codePoints.length
                ? codePoints.length + 1
                : match.end + 1)
          : match.end;
    }
    _appendCodePoints(
      output,
      codePoints,
      copiedUntil,
      codePoints.length,
      consumeStep,
    );
    return output.toString();
  }

  PortableRegexMatch? _find(
    List<int> codePoints,
    int fromIndex,
    void Function() consumeStep,
  ) {
    final emptyCaptures = List<int>.filled((groupCount + 1) * 2, _unsetCapture);
    var current = <_MachineThread>[];
    PortableRegexMatch? best;
    for (var position = fromIndex; position <= codePoints.length; position++) {
      consumeStep();
      final seeds = best == null
          ? [...current, _MachineThread(_start, emptyCaptures, start: position)]
          : current;
      current = _closure(seeds, position, codePoints.length, consumeStep);
      final matchIndex = current.indexWhere(
        (thread) =>
            _instructions[thread.instruction].kind == _InstructionKind.match,
      );
      if (matchIndex >= 0) {
        best = PortableRegexMatch(current[matchIndex].captures);
        current = current.sublist(0, matchIndex);
        if (current.isEmpty) return best;
      }
      if (position == codePoints.length) break;
      current = _consume(current, codePoints[position], consumeStep);
    }
    return best;
  }

  List<_MachineThread> _advance(
    List<_MachineThread> current,
    int codePoint,
    int position,
    int length,
    void Function() consumeStep,
  ) => _closure(
    _consume(current, codePoint, consumeStep),
    position,
    length,
    consumeStep,
  );

  List<_MachineThread> _consume(
    List<_MachineThread> current,
    int codePoint,
    void Function() consumeStep,
  ) {
    final result = <_MachineThread>[];
    for (final thread in current) {
      final instruction = _instructions[thread.instruction];
      switch (instruction.kind) {
        case _InstructionKind.character:
          consumeStep();
          if (instruction.predicate!(codePoint)) {
            result.add(thread.copyWith(instruction: instruction.next));
          }
        case _InstructionKind.repeat:
          consumeStep();
          if (instruction.predicate!(codePoint)) {
            final nextCount = thread.repeatCount + 1;
            result.add(
              thread.copyWith(
                repeatInstruction: thread.instruction,
                repeatCount: instruction.maximum == null
                    ? nextCount.clamp(0, instruction.minimum!)
                    : nextCount,
              ),
            );
          }
        default:
          break;
      }
    }
    return result;
  }

  List<_MachineThread> _closure(
    List<_MachineThread> seeds,
    int position,
    int length,
    void Function() consumeStep,
  ) {
    final result = <_MachineThread>[];
    final pending = ListQueue<_MachineThread>.from(seeds);
    final seen = <(int, int, int)>{};
    while (pending.isNotEmpty) {
      final thread = pending.removeFirst();
      final identity = (
        thread.instruction,
        thread.repeatInstruction,
        thread.repeatCount,
      );
      if (!seen.add(identity)) continue;
      consumeStep();
      final instruction = _instructions[thread.instruction];
      switch (instruction.kind) {
        case _InstructionKind.jump:
          pending.addFirst(thread.copyWith(instruction: instruction.next));
        case _InstructionKind.split:
          pending
            ..addFirst(thread.copyWith(instruction: instruction.alternative))
            ..addFirst(thread.copyWith(instruction: instruction.preferred));
        case _InstructionKind.save:
          final captures = List<int>.of(thread.captures);
          captures[instruction.slot!] = position;
          pending.addFirst(
            thread.copyWith(instruction: instruction.next, captures: captures),
          );
        case _InstructionKind.start:
          if (position == 0) {
            pending.addFirst(thread.copyWith(instruction: instruction.next));
          }
        case _InstructionKind.end:
          if (position == length) {
            pending.addFirst(thread.copyWith(instruction: instruction.next));
          }
        case _InstructionKind.repeat:
          final count = thread.repeatInstruction == thread.instruction
              ? thread.repeatCount
              : 0;
          if (instruction.maximum == null || count < instruction.maximum!) {
            result.add(thread);
          }
          if (count >= instruction.minimum!) {
            pending.addFirst(
              thread.copyWith(
                instruction: instruction.next,
                repeatInstruction: _noRepeat,
                repeatCount: 0,
              ),
            );
          }
        case _InstructionKind.character:
        case _InstructionKind.match:
          result.add(thread);
      }
    }
    return result;
  }
}

final class PortableRegexMatch {
  const PortableRegexMatch(this.captures);

  final List<int> captures;

  int get start => captures[0];

  int get end => captures[1];

  String? group(String input, int index) {
    if (index < 0 || index * 2 + 1 >= captures.length) return null;
    final start = captures[index * 2];
    final end = captures[index * 2 + 1];
    if (start == _unsetCapture || end == _unsetCapture) return null;
    final codePoints = input.runes.toList(growable: false);
    return String.fromCharCodes(codePoints.sublist(start, end));
  }
}

final class PortableRegexCompileFailure implements Exception {
  const PortableRegexCompileFailure(this.message);

  final String message;
}

final class _MachineThread {
  const _MachineThread(
    this.instruction,
    this.captures, {
    this.start = 0,
    this.repeatInstruction = _noRepeat,
    this.repeatCount = 0,
  });

  final int instruction;
  final List<int> captures;
  final int start;
  final int repeatInstruction;
  final int repeatCount;

  _MachineThread copyWith({
    int? instruction,
    List<int>? captures,
    int? repeatInstruction,
    int? repeatCount,
  }) => _MachineThread(
    instruction ?? this.instruction,
    captures ?? this.captures,
    start: start,
    repeatInstruction: repeatInstruction ?? this.repeatInstruction,
    repeatCount: repeatCount ?? this.repeatCount,
  );
}

enum _InstructionKind {
  jump,
  character,
  repeat,
  split,
  save,
  start,
  end,
  match,
}

final class _RegexInstruction {
  _RegexInstruction(
    this.kind, {
    this.predicate,
    this.minimum,
    this.maximum,
    this.slot,
    this.preferred = _unpatched,
    this.alternative = _unpatched,
  });

  final _InstructionKind kind;
  final bool Function(int)? predicate;
  final int? minimum;
  final int? maximum;
  final int? slot;
  int next = _unpatched;
  int preferred;
  int alternative;
}

sealed class _ParsedRegex {
  const _ParsedRegex();
}

final class _ParsedEmpty extends _ParsedRegex {
  const _ParsedEmpty();
}

final class _ParsedCharacter extends _ParsedRegex {
  const _ParsedCharacter(this.predicate);

  final bool Function(int) predicate;
}

final class _ParsedStart extends _ParsedRegex {
  const _ParsedStart();
}

final class _ParsedEnd extends _ParsedRegex {
  const _ParsedEnd();
}

final class _ParsedSequence extends _ParsedRegex {
  const _ParsedSequence(this.values);

  final List<_ParsedRegex> values;
}

final class _ParsedAlternate extends _ParsedRegex {
  const _ParsedAlternate(this.values);

  final List<_ParsedRegex> values;
}

final class _ParsedGroup extends _ParsedRegex {
  const _ParsedGroup(this.index, this.value);

  final int index;
  final _ParsedRegex value;
}

final class _ParsedRepeat extends _ParsedRegex {
  const _ParsedRepeat(this.value, this.minimum, this.maximum);

  final _ParsedCharacter value;
  final int minimum;
  final int? maximum;
}

final class _PortableRegexParser {
  _PortableRegexParser(this.pattern);

  final String pattern;
  int index = 0;
  int groupCount = 0;

  _ParsedRegex parse() {
    final result = _alternative();
    if (index != pattern.length) {
      _fail("The regular expression contains an unexpected closing group");
    }
    return result;
  }

  _ParsedRegex _alternative() {
    final choices = <_ParsedRegex>[_sequence()];
    while (_peek() == "|") {
      index++;
      choices.add(_sequence());
    }
    return choices.length == 1 ? choices.single : _ParsedAlternate(choices);
  }

  _ParsedRegex _sequence() {
    final values = <_ParsedRegex>[];
    while (index < pattern.length && _peek() != ")" && _peek() != "|") {
      values.add(_quantified());
    }
    return switch (values.length) {
      0 => const _ParsedEmpty(),
      1 => values.single,
      _ => _ParsedSequence(values),
    };
  }

  _ParsedRegex _quantified() {
    final value = _atom();
    final marker = _peek();
    final (int, int?) bounds;
    switch (marker) {
      case "*":
        bounds = (0, null);
      case "+":
        bounds = (1, null);
      case "?":
        bounds = (0, 1);
      case "{":
        bounds = _repetitionBounds();
      default:
        return value;
    }
    if (marker != "{") index++;
    if (value is! _ParsedCharacter) {
      _fail("Only character atoms can be repeated");
    }
    return _ParsedRepeat(value, bounds.$1, bounds.$2);
  }

  (int, int?) _repetitionBounds() {
    final end = pattern.indexOf("}", index + 1);
    if (end < 0) {
      _fail("The regular expression contains an unterminated repetition");
    }
    final parts = pattern.substring(index + 1, end).split(",");
    if (parts.isEmpty ||
        parts.length > 2 ||
        parts.first.isEmpty ||
        parts.first.split("").any((value) => !_isDigit(value)) ||
        (parts.length == 2 &&
            parts[1].isNotEmpty &&
            parts[1].split("").any((value) => !_isDigit(value)))) {
      _fail("The regular expression contains an invalid repetition");
    }
    final minimum = int.tryParse(parts.first);
    if (minimum == null) {
      _fail("The regular expression contains an invalid repetition");
    }
    final maximum = parts.length == 1
        ? minimum
        : (parts[1].isEmpty ? null : int.tryParse(parts[1]));
    if (parts.length == 2 && parts[1].isNotEmpty && maximum == null) {
      _fail("The regular expression contains an invalid repetition");
    }
    if (maximum != null && minimum > maximum) {
      _fail("The regular expression repetition range is reversed");
    }
    index = end + 1;
    return (minimum, maximum);
  }

  _ParsedRegex _atom() {
    final value = _takeRune();
    switch (value) {
      case 40:
        groupCount++;
        final group = groupCount;
        final body = _alternative();
        if (_takeRune() != 41) {
          _fail("The regular expression contains an unterminated group");
        }
        return _ParsedGroup(group, body);
      case 46:
        return _ParsedCharacter(
          (codePoint) => !_dotExclusions.contains(codePoint),
        );
      case 94:
        return const _ParsedStart();
      case 36:
        return const _ParsedEnd();
      case 91:
        return _characterClass();
      case 92:
        return _escape();
      default:
        return _ParsedCharacter((codePoint) => codePoint == value);
    }
  }

  _ParsedRegex _characterClass() {
    final negate = _peek() == "^";
    if (negate) index++;
    final predicates = <bool Function(int)>[];
    while (index < pattern.length && _peek() != "]") {
      final first = _classAtom();
      if (_peek() == "-" && _peekAt(index + 1) != "]") {
        index++;
        final last = _classAtom();
        final minimum = first.literal;
        final maximum = last.literal;
        if (minimum == null || maximum == null || minimum > maximum) {
          _fail("The regular expression contains an invalid character range");
        }
        predicates.add(
          (codePoint) => codePoint >= minimum && codePoint <= maximum,
        );
      } else {
        predicates.add(first.predicate);
      }
    }
    if (_takeRune() != 93) {
      _fail("The regular expression contains an unterminated character class");
    }
    return _ParsedCharacter(
      negate
          ? (codePoint) => !predicates.any((predicate) => predicate(codePoint))
          : (codePoint) => predicates.any((predicate) => predicate(codePoint)),
    );
  }

  _ClassAtom _classAtom() {
    if (_peek() != r"\") {
      final codePoint = _takeRune();
      return _ClassAtom((value) => value == codePoint, codePoint);
    }
    index++;
    return _escapedClassAtom();
  }

  _ParsedCharacter _escape() => _ParsedCharacter(_escapedClassAtom().predicate);

  _ClassAtom _escapedClassAtom() {
    final marker = _takeRune();
    return switch (marker) {
      100 => _predicateAtom((value) => value >= 48 && value <= 57),
      68 => _predicateAtom((value) => value < 48 || value > 57),
      119 => _predicateAtom(_isAsciiWord),
      87 => _predicateAtom((value) => !_isAsciiWord(value)),
      115 => _predicateAtom(_portableWhitespaceCodePoints.contains),
      83 => _predicateAtom(
        (value) => !_portableWhitespaceCodePoints.contains(value),
      ),
      120 => _literalAtom(_fixedHex(2)),
      117 => _literalAtom(_fixedHex(4)),
      48 => _literalAtom(0),
      110 => _literalAtom(10),
      114 => _literalAtom(13),
      116 => _literalAtom(9),
      102 => _literalAtom(12),
      _ => _literalAtom(marker),
    };
  }

  int _fixedHex(int digits) {
    final end = index + digits;
    if (end > pattern.length) {
      _fail("The regular expression contains an incomplete hexadecimal escape");
    }
    final value = int.tryParse(pattern.substring(index, end), radix: 16);
    if (value == null) {
      _fail("The regular expression contains an invalid hexadecimal escape");
    }
    index = end;
    return value;
  }

  int _takeRune() {
    if (index >= pattern.length) {
      _fail("The regular expression ended unexpectedly");
    }
    final value = _codePointAt(pattern, index);
    index += value > 0xffff ? 2 : 1;
    return value;
  }

  String? _peek() => _peekAt(index);

  String? _peekAt(int offset) =>
      offset < pattern.length ? pattern.substring(offset, offset + 1) : null;

  Never _fail(String message) => throw PortableRegexCompileFailure(message);
}

final class _ClassAtom {
  const _ClassAtom(this.predicate, this.literal);

  final bool Function(int) predicate;
  final int? literal;
}

_ClassAtom _predicateAtom(bool Function(int) predicate) =>
    _ClassAtom(predicate, null);

_ClassAtom _literalAtom(int value) =>
    _ClassAtom((actual) => actual == value, value);

final class _RegexFragment {
  const _RegexFragment(this.start, this.exits);

  final int start;
  final List<_RegexExit> exits;
}

final class _RegexExit {
  const _RegexExit(this.instruction, this.link);

  final int instruction;
  final _RegexLink link;
}

enum _RegexLink { next, preferred, alternative }

final class _RegexProgram {
  const _RegexProgram(this.instructions, this.start);

  final List<_RegexInstruction> instructions;
  final int start;
}

final class _PortableRegexCompiler {
  _PortableRegexCompiler(this.limit);

  final int limit;
  final List<_RegexInstruction> _instructions = [];

  _RegexProgram finish(_ParsedRegex value) {
    final opening = _emit(_RegexInstruction(_InstructionKind.save, slot: 0));
    final body = _compile(value);
    final closing = _emit(_RegexInstruction(_InstructionKind.save, slot: 1));
    final accepted = _emit(_RegexInstruction(_InstructionKind.match));
    _patchOne(opening, _RegexLink.next, body.start);
    _patch(body.exits, closing);
    _patchOne(closing, _RegexLink.next, accepted);
    return _RegexProgram(List.unmodifiable(_instructions), opening);
  }

  _RegexFragment _compile(_ParsedRegex value) => switch (value) {
    _ParsedEmpty() => _single(_RegexInstruction(_InstructionKind.jump)),
    _ParsedCharacter(:final predicate) => _single(
      _RegexInstruction(_InstructionKind.character, predicate: predicate),
    ),
    _ParsedStart() => _single(_RegexInstruction(_InstructionKind.start)),
    _ParsedEnd() => _single(_RegexInstruction(_InstructionKind.end)),
    _ParsedSequence(:final values) => values.map(_compile).reduce((
      current,
      next,
    ) {
      _patch(current.exits, next.start);
      return _RegexFragment(current.start, next.exits);
    }),
    _ParsedAlternate(:final values) => values.map(_compile).reduce((
      current,
      next,
    ) {
      final split = _emit(
        _RegexInstruction(
          _InstructionKind.split,
          preferred: current.start,
          alternative: next.start,
        ),
      );
      return _RegexFragment(split, [...current.exits, ...next.exits]);
    }),
    _ParsedGroup(:final index, :final value) => _compileGroup(index, value),
    _ParsedRepeat(:final value, :final minimum, :final maximum) => _single(
      _RegexInstruction(
        _InstructionKind.repeat,
        predicate: value.predicate,
        minimum: minimum,
        maximum: maximum,
      ),
    ),
  };

  _RegexFragment _compileGroup(int index, _ParsedRegex value) {
    final opening = _emit(
      _RegexInstruction(_InstructionKind.save, slot: index * 2),
    );
    final body = _compile(value);
    final closing = _emit(
      _RegexInstruction(_InstructionKind.save, slot: index * 2 + 1),
    );
    _patchOne(opening, _RegexLink.next, body.start);
    _patch(body.exits, closing);
    return _RegexFragment(opening, [_RegexExit(closing, _RegexLink.next)]);
  }

  _RegexFragment _single(_RegexInstruction instruction) {
    final index = _emit(instruction);
    return _RegexFragment(index, [_RegexExit(index, _RegexLink.next)]);
  }

  int _emit(_RegexInstruction instruction) {
    if (_instructions.length >= limit) {
      throw const PortableRegexCompileFailure(
        "The regular expression program exceeds its limit",
      );
    }
    _instructions.add(instruction);
    return _instructions.length - 1;
  }

  void _patch(List<_RegexExit> exits, int target) {
    for (final exit in exits) {
      _patchOne(exit.instruction, exit.link, target);
    }
  }

  void _patchOne(int instructionIndex, _RegexLink link, int target) {
    final instruction = _instructions[instructionIndex];
    switch (link) {
      case _RegexLink.next:
        instruction.next = target;
      case _RegexLink.preferred:
        instruction.preferred = target;
      case _RegexLink.alternative:
        instruction.alternative = target;
    }
  }
}

void _appendReplacement(
  StringBuffer output,
  String replacement,
  List<int> codePoints,
  List<int> captures,
  int groupCount,
  void Function() consumeStep,
) {
  var index = 0;
  while (index < replacement.length) {
    final marker = _codePointAt(replacement, index);
    index += marker > 0xffff ? 2 : 1;
    switch (marker) {
      case 92:
        if (index == replacement.length) {
          throw const PortableRegexCompileFailure(
            "The regular expression replacement is invalid",
          );
        }
        final escaped = _codePointAt(replacement, index);
        consumeStep();
        output.writeCharCode(escaped);
        index += escaped > 0xffff ? 2 : 1;
      case 36:
        if (index == replacement.length ||
            !_isDigit(replacement.substring(index, index + 1))) {
          throw const PortableRegexCompileFailure(
            "The regular expression replacement is invalid",
          );
        }
        var group = int.parse(replacement.substring(index, index + 1));
        if (group > groupCount) {
          throw const PortableRegexCompileFailure(
            "The regular expression replacement is invalid",
          );
        }
        index++;
        while (index < replacement.length &&
            _isDigit(replacement.substring(index, index + 1))) {
          final candidate =
              group * 10 + int.parse(replacement.substring(index, index + 1));
          if (candidate > groupCount) break;
          group = candidate;
          index++;
        }
        final captureStart = captures[group * 2];
        final captureEnd = captures[group * 2 + 1];
        if (captureStart != _unsetCapture && captureEnd != _unsetCapture) {
          _appendCodePoints(
            output,
            codePoints,
            captureStart,
            captureEnd,
            consumeStep,
          );
        }
      default:
        consumeStep();
        output.writeCharCode(marker);
    }
  }
}

void _appendCodePoints(
  StringBuffer output,
  List<int> codePoints,
  int start,
  int end,
  void Function() consumeStep,
) {
  for (var index = start; index < end; index++) {
    consumeStep();
    output.writeCharCode(codePoints[index]);
  }
}

bool _isAsciiWord(int codePoint) =>
    codePoint == 95 ||
    (codePoint >= 48 && codePoint <= 57) ||
    (codePoint >= 65 && codePoint <= 90) ||
    (codePoint >= 97 && codePoint <= 122);

int _codePointAt(String source, int index) {
  final first = source.codeUnitAt(index);
  if (first < 0xd800 || first > 0xdbff || index + 1 >= source.length) {
    return first;
  }
  final second = source.codeUnitAt(index + 1);
  if (second < 0xdc00 || second > 0xdfff) return first;
  return 0x10000 + ((first - 0xd800) << 10) + second - 0xdc00;
}

const _unpatched = -1;
const _unsetCapture = -1;
const _noRepeat = -1;
const _dotExclusions = {10, 13, 0x2028, 0x2029};
const _portableWhitespaceCodePoints = {
  0x0009,
  0x000a,
  0x000b,
  0x000c,
  0x000d,
  0x0020,
  0x0085,
  0x00a0,
  0x1680,
  0x2000,
  0x2001,
  0x2002,
  0x2003,
  0x2004,
  0x2005,
  0x2006,
  0x2007,
  0x2008,
  0x2009,
  0x200a,
  0x2028,
  0x2029,
  0x202f,
  0x205f,
  0x3000,
  0xfeff,
};
