import "package:typewriter_panel/infrastructure/protocols/operations/skirout/portable_unicode_tables.dart";
import "package:typewriter_panel/typewriter_panel.dart";

// Unicode text semantics of the portable expression language: case mapping,
// case folding, normalization and white space, all from the pinned release in
// `PortableUnicodeTables`. Nothing here consults Dart's or JavaScript's case or
// normalization behavior, so the panel on the VM and on the web produces
// exactly what Realm's `PortableUnicode.kt` produces for every input.
//
// Strings are processed by code point; an unpaired surrogate is a code point
// without mappings. Case operations apply the default, untailored mappings of
// the Unicode Standard (section 3.13): no locale changes them, and the only
// conditional mapping is Final_Sigma. Tables are decoded once, at first use.

/// Full lowercase mapping of [value]; U+03A3 maps to final sigma U+03C2 where
/// the Unicode Final_Sigma condition holds.
String portableLower(String value) {
  final codePoints = value.runes.toList(growable: false);
  final output = StringBuffer();
  for (var index = 0; index < codePoints.length; index++) {
    _writeLower(output, codePoints, index);
  }
  return output.toString();
}

/// Full uppercase mapping of [value], such as `ß` to `SS`.
String portableUpper(String value) => _mapCodePoints(value, _caseTables.upper);

/// Titlecases each word of [value]: the first code point of the text and every
/// code point after a [portableIsWhiteSpace] code point take their full
/// titlecase mapping, and all others their full lowercase mapping, including
/// Final_Sigma.
String portableTitle(String value) {
  final codePoints = value.runes.toList(growable: false);
  final output = StringBuffer();
  for (var index = 0; index < codePoints.length; index++) {
    if (index == 0 || portableIsWhiteSpace(codePoints[index - 1])) {
      _writeCodePoints(output, _caseTables.title(codePoints[index]));
    } else {
      _writeLower(output, codePoints, index);
    }
  }
  return output.toString();
}

/// Full case folding of [value] (CaseFolding.txt statuses C and F), for
/// caseless comparison.
String portableFoldCase(String value) =>
    _mapCodePoints(value, _caseTables.fold);

/// Normalizes [value] per UAX #15: NFD without [compatibility] or [compose],
/// NFC with [compose], NFKD with [compatibility], and NFKC with both.
///
/// Decomposition is full and recursive, combining marks are put in canonical
/// order, and composition skips fully excluded composites. Hangul syllables
/// decompose and compose algorithmically.
String portableNormalize(
  String value, {
  required bool compatibility,
  required bool compose,
}) {
  final tables = _normalizationTables;
  final buffer = <int>[];
  for (final codePoint in value.runes) {
    tables.decompose(codePoint, buffer, compatibility: compatibility);
  }
  tables.orderCanonically(buffer);
  if (compose) tables.compose(buffer);
  return String.fromCharCodes(buffer);
}

/// Whether [codePoint] has the White_Space property or is U+FEFF ZERO WIDTH
/// NO-BREAK SPACE.
bool portableIsWhiteSpace(int codePoint) =>
    _caseTables.whiteSpace.contains(codePoint);

/// Removes the leading [portableIsWhiteSpace] code points of [value].
String portableTrimStart(String value) {
  final runes = RuneIterator(value);
  while (runes.moveNext()) {
    if (!portableIsWhiteSpace(runes.current)) {
      return value.substring(runes.rawIndex);
    }
  }
  return "";
}

/// Removes the trailing [portableIsWhiteSpace] code points of [value].
String portableTrimEnd(String value) {
  final runes = RuneIterator.at(value, value.length);
  while (runes.movePrevious()) {
    if (!portableIsWhiteSpace(runes.current)) {
      return value.substring(0, runes.rawIndex + runes.currentSize);
    }
  }
  return "";
}

String _mapCodePoints(String value, List<int> Function(int) mapping) {
  final output = StringBuffer();
  for (final codePoint in value.runes) {
    _writeCodePoints(output, mapping(codePoint));
  }
  return output.toString();
}

void _writeLower(StringBuffer output, List<int> codePoints, int index) {
  final codePoint = codePoints[index];
  final finalSigma = _caseTables.finalSigmaLower[codePoint];
  _writeCodePoints(
    output,
    finalSigma != null && _isFinalSigma(codePoints, index)
        ? finalSigma
        : _caseTables.lower(codePoint),
  );
}

/// The Final_Sigma condition: a cased code point, then only case ignorable
/// ones, precede [index], and no case ignorable run followed by a cased code
/// point follows it. A code point that is both cased and case ignorable counts
/// as cased, so it satisfies the preceding part and fails the following part.
bool _isFinalSigma(List<int> codePoints, int index) {
  final tables = _caseTables;
  for (var before = index - 1; ; before--) {
    if (before < 0) return false;
    final codePoint = codePoints[before];
    if (tables.cased.contains(codePoint)) break;
    if (!tables.caseIgnorable.contains(codePoint)) return false;
  }
  for (var after = index + 1; after < codePoints.length; after++) {
    final codePoint = codePoints[after];
    if (tables.cased.contains(codePoint)) return false;
    if (!tables.caseIgnorable.contains(codePoint)) return true;
  }
  return true;
}

void _writeCodePoints(StringBuffer output, List<int> codePoints) {
  codePoints.forEach(output.writeCharCode);
}

final _caseTables = _CaseTables();
final _normalizationTables = _NormalizationTables();

/// The decoded case and white space tables.
final class _CaseTables {
  final whiteSpace = _RangeSet(PortableUnicodeTables.whiteSpace);
  final cased = _RangeSet(PortableUnicodeTables.cased);
  final caseIgnorable = _RangeSet(PortableUnicodeTables.caseIgnorable);
  final finalSigmaLower = _multiMap(PortableUnicodeTables.finalSigmaLower);
  final _simpleUpper = _CaseRuns(PortableUnicodeTables.simpleUpper);
  final _simpleLower = _CaseRuns(PortableUnicodeTables.simpleLower);
  final _simpleTitle = _CaseRuns(PortableUnicodeTables.simpleTitle);
  final _simpleFold = _CaseRuns(PortableUnicodeTables.simpleFold);
  final _specialUpper = _multiMap(PortableUnicodeTables.specialUpper);
  final _specialLower = _multiMap(PortableUnicodeTables.specialLower);
  final _specialTitle = _multiMap(PortableUnicodeTables.specialTitle);
  final _fullFold = _multiMap(PortableUnicodeTables.fullFold);

  List<int> upper(int codePoint) =>
      _specialUpper[codePoint] ?? [_simpleUpper.map(codePoint)];

  List<int> lower(int codePoint) =>
      _specialLower[codePoint] ?? [_simpleLower.map(codePoint)];

  List<int> title(int codePoint) =>
      _specialTitle[codePoint] ?? [_simpleTitle.map(codePoint)];

  List<int> fold(int codePoint) =>
      _fullFold[codePoint] ?? [_simpleFold.map(codePoint)];
}

const _sBase = 0xac00;
const _lBase = 0x1100;
const _vBase = 0x1161;
const _tBase = 0x11a7;
const _lCount = 19;
const _vCount = 21;
const _tCount = 28;
const _nCount = _vCount * _tCount;
const _sCount = _lCount * _nCount;
const _codePointLimit = 0x110000;

/// The decoded normalization tables and the UAX #15 steps that use them.
final class _NormalizationTables {
  factory _NormalizationTables() {
    final canonical = <int, List<int>>{};
    final compatibility = <int, List<int>>{};
    final reader = _TableReader(PortableUnicodeTables.decompositions);
    var codePoint = 0;
    var previous = const [0];
    while (reader.hasNext) {
      codePoint += reader.next();
      final header = reader.next();
      final reference = previous;
      final mapping = List.generate(
        header ~/ 2,
        (index) =>
            reference[min(index, reference.length - 1)] + reader.nextSigned(),
        growable: false,
      );
      (header.isOdd ? compatibility : canonical)[codePoint] = mapping;
      previous = mapping;
    }
    final composites = <int, int>{};
    final primaries = _TableReader(
      PortableUnicodeTables.primaryComposites,
    );
    var primary = 0;
    while (primaries.hasNext) {
      primary += primaries.next();
      final pair = canonical[primary]!;
      composites[_pairKey(pair[0], pair[1])] = primary;
    }
    return _NormalizationTables._(
      _ClassRuns(PortableUnicodeTables.combiningClasses),
      canonical,
      compatibility,
      composites,
    );
  }

  _NormalizationTables._(
    this._combiningClasses,
    this._canonical,
    this._compatibility,
    this._composites,
  );

  final _ClassRuns _combiningClasses;
  final Map<int, List<int>> _canonical;
  final Map<int, List<int>> _compatibility;
  final Map<int, int> _composites;

  /// Appends the full decomposition of [codePoint] to [output].
  void decompose(
    int codePoint,
    List<int> output, {
    required bool compatibility,
  }) {
    final syllable = codePoint - _sBase;
    if (syllable >= 0 && syllable < _sCount) {
      output
        ..add(_lBase + syllable ~/ _nCount)
        ..add(_vBase + syllable % _nCount ~/ _tCount);
      if (syllable % _tCount != 0) output.add(_tBase + syllable % _tCount);
      return;
    }
    final mapping =
        _canonical[codePoint] ??
        (compatibility ? _compatibility[codePoint] : null);
    if (mapping == null) {
      output.add(codePoint);
      return;
    }
    for (final mapped in mapping) {
      decompose(mapped, output, compatibility: compatibility);
    }
  }

  /// Stably sorts every run of nonzero combining classes by class.
  void orderCanonically(List<int> buffer) {
    for (var index = 1; index < buffer.length; index++) {
      final codePoint = buffer[index];
      final combiningClass = _combiningClasses.value(codePoint);
      if (combiningClass == 0) continue;
      var target = index;
      while (target > 0 &&
          _combiningClasses.value(buffer[target - 1]) > combiningClass) {
        buffer[target] = buffer[target - 1];
        target--;
      }
      buffer[target] = codePoint;
    }
  }

  /// Canonically composes a decomposed, canonically ordered buffer in place.
  void compose(List<int> buffer) {
    if (buffer.isEmpty) return;
    var starter = 0;
    var lastClass = _combiningClasses.value(buffer[0]) == 0 ? 0 : 256;
    var size = 1;
    for (var index = 1; index < buffer.length; index++) {
      final codePoint = buffer[index];
      final combiningClass = _combiningClasses.value(codePoint);
      final composite = _composePair(buffer[starter], codePoint);
      if (composite >= 0 && (lastClass == 0 || lastClass < combiningClass)) {
        buffer[starter] = composite;
        continue;
      }
      if (combiningClass == 0) starter = size;
      lastClass = combiningClass;
      buffer[size++] = codePoint;
    }
    buffer.length = size;
  }

  /// The primary composite of [first] and [second], or -1.
  int _composePair(int first, int second) {
    final leading = first - _lBase;
    final vowel = second - _vBase;
    if (leading >= 0 && leading < _lCount && vowel >= 0 && vowel < _vCount) {
      return _sBase + (leading * _vCount + vowel) * _tCount;
    }
    final syllable = first - _sBase;
    final trailing = second - _tBase;
    if (syllable >= 0 &&
        syllable < _sCount &&
        syllable % _tCount == 0 &&
        trailing > 0 &&
        trailing < _tCount) {
      return first + trailing;
    }
    return _composites[_pairKey(first, second)] ?? -1;
  }
}

/// A composite pair key, built arithmetically so it stays exact on the web.
int _pairKey(int first, int second) => first * _codePointLimit + second;

final _continuationDigits =
    PortableUnicodeTables.alphabet.length -
    PortableUnicodeTables.terminalDigits;

final _digits = () {
  final digits = List.filled(128, -1);
  final alphabet = PortableUnicodeTables.alphabet;
  for (var value = 0; value < alphabet.length; value++) {
    digits[alphabet.codeUnitAt(value)] = value;
  }
  return digits;
}();

/// Reads the unsigned and zigzag signed numbers of one table.
final class _TableReader {
  _TableReader(this._data);

  final String _data;
  var _index = 0;

  bool get hasNext => _index < _data.length;

  int next() {
    const terminal = PortableUnicodeTables.terminalDigits;
    var value = 0;
    while (true) {
      final digit = _digits[_data.codeUnitAt(_index++)];
      if (digit < terminal) return value * terminal + digit;
      value = value * _continuationDigits + digit - terminal;
    }
  }

  int nextSigned() {
    final value = next();
    return value.isEven ? value ~/ 2 : -(value + 1) ~/ 2;
  }
}

/// The greatest index of [starts] whose start is at most [codePoint], or -1.
int _floorIndex(Int32List starts, int codePoint) {
  var low = 0;
  var high = starts.length - 1;
  while (low <= high) {
    final middle = (low + high) ~/ 2;
    if (starts[middle] <= codePoint) {
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }
  return high;
}

/// A set of disjoint, ascending code point ranges.
final class _RangeSet {
  factory _RangeSet(String data) {
    final reader = _TableReader(data);
    final starts = <int>[];
    final ends = <int>[];
    var end = 0;
    while (reader.hasNext) {
      final start = end + reader.next();
      end = start + reader.next();
      starts.add(start);
      ends.add(end);
    }
    return _RangeSet._(Int32List.fromList(starts), Int32List.fromList(ends));
  }

  _RangeSet._(this._starts, this._ends);

  final Int32List _starts;
  final Int32List _ends;

  bool contains(int codePoint) {
    final index = _floorIndex(_starts, codePoint);
    return index >= 0 && codePoint < _ends[index];
  }
}

/// Simple case mappings as runs of code points that share a delta.
final class _CaseRuns {
  factory _CaseRuns(String data) {
    final reader = _TableReader(data);
    final starts = <int>[];
    final ends = <int>[];
    final strides = <int>[];
    final deltas = <int>[];
    var end = 0;
    while (reader.hasNext) {
      final start = end + reader.next();
      final shape = reader.next();
      final stride = shape.isOdd ? 2 : 1;
      end = start + shape ~/ 2 * stride + 1;
      starts.add(start);
      ends.add(end);
      strides.add(stride);
      deltas.add(reader.nextSigned());
    }
    return _CaseRuns._(
      Int32List.fromList(starts),
      Int32List.fromList(ends),
      Int32List.fromList(strides),
      Int32List.fromList(deltas),
    );
  }

  _CaseRuns._(this._starts, this._ends, this._strides, this._deltas);

  final Int32List _starts;
  final Int32List _ends;
  final Int32List _strides;
  final Int32List _deltas;

  /// The mapping of [codePoint], or [codePoint] itself when it has none.
  int map(int codePoint) {
    final index = _floorIndex(_starts, codePoint);
    if (index < 0 ||
        codePoint >= _ends[index] ||
        (codePoint - _starts[index]) % _strides[index] != 0) {
      return codePoint;
    }
    return codePoint + _deltas[index];
  }
}

/// Nonzero canonical combining classes as runs of equal class.
final class _ClassRuns {
  factory _ClassRuns(String data) {
    final reader = _TableReader(data);
    final starts = <int>[];
    final ends = <int>[];
    final values = <int>[];
    var end = 0;
    while (reader.hasNext) {
      final start = end + reader.next();
      end = start + reader.next();
      starts.add(start);
      ends.add(end);
      values.add(reader.next());
    }
    return _ClassRuns._(
      Int32List.fromList(starts),
      Int32List.fromList(ends),
      Int32List.fromList(values),
    );
  }

  _ClassRuns._(this._starts, this._ends, this._values);

  final Int32List _starts;
  final Int32List _ends;
  final Int32List _values;

  int value(int codePoint) {
    final index = _floorIndex(_starts, codePoint);
    return index >= 0 && codePoint < _ends[index] ? _values[index] : 0;
  }
}

/// Decodes a multi map table: code points with a mapping of several code
/// points.
Map<int, List<int>> _multiMap(String data) {
  final reader = _TableReader(data);
  final mappings = <int, List<int>>{};
  var codePoint = 0;
  while (reader.hasNext) {
    codePoint += reader.next();
    final count = reader.next();
    mappings[codePoint] = List.generate(
      count,
      (_) => reader.next(),
      growable: false,
    );
  }
  return mappings;
}
