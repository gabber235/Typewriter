import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// A set of [LogicalKeyboardKey]s that can be used as the keys in a map,
/// preserving the insertion order for display purposes.
///
/// [SortedLogicalKeyActivator] can be used as a [ShortcutActivator]. It is not
/// recommended to use [SortedLogicalKeyActivator] for a common shortcut such as
/// `Delete` or `Ctrl+C`, prefer [SingleActivator] when possible, whose behavior
/// more closely resembles that of typical platforms.
///
/// When used as a [ShortcutActivator], [SortedLogicalKeyActivator] will
/// activate the intent when all [keys] are pressed, and no others, except that
/// modifier keys are considered without considering sides (e.g. control left
/// and control right are considered the same).
///
/// This behaves like [LogicalKeySet], but unlike [LogicalKeySet] (which stores
/// keys in a hash set and sorts them for debug descriptions), this class keeps
/// the original insertion order supplied by the caller so that the displayed
/// shortcut text matches the authored order.
///
/// This is also a thin wrapper around a collection of keys, but changes the
/// equality comparison from an identity comparison to a contents comparison so
/// that non-identical collections with the same keys in them will compare as
/// equal.
class SortedLogicalKeyActivator
    with Diagnosticable
    implements ShortcutActivator {
  /// A constructor for making a [SortedLogicalKeyActivator] of up to four keys.
  ///
  /// If you need more than four keys, use [SortedLogicalKeyActivator.fromList].
  ///
  /// The same [LogicalKeyboardKey] may not appear more than once in the set.
  SortedLogicalKeyActivator(
    LogicalKeyboardKey key1, [
    LogicalKeyboardKey? key2,
    LogicalKeyboardKey? key3,
    LogicalKeyboardKey? key4,
  ]) : _orderedKeys = <LogicalKeyboardKey>[key1, ?key2, ?key3, ?key4] {
    _validateUnique();
  }

  /// Create a [SortedLogicalKeyActivator] from a list of [LogicalKeyboardKey]s.
  ///
  /// Do not mutate the `keys` list after passing it to this object.
  ///
  /// The `keys` list must not be empty and must not contain duplicates.
  SortedLogicalKeyActivator.fromList(List<LogicalKeyboardKey> keys)
    : assert(keys.isNotEmpty, "The list of keys must not be empty."),
      _orderedKeys = List<LogicalKeyboardKey>.unmodifiable(keys) {
    _validateUnique();
  }

  final List<LogicalKeyboardKey> _orderedKeys;
  late final Set<LogicalKeyboardKey> _keySet = _orderedKeys.toSet();

  /// Returns the keys in the original insertion order.
  List<LogicalKeyboardKey> get orderedKeys =>
      List<LogicalKeyboardKey>.unmodifiable(_orderedKeys);

  /// Returns a copy of the logical keys (order not guaranteed).
  Set<LogicalKeyboardKey> get keys => Set<LogicalKeyboardKey>.from(_keySet);

  void _validateUnique() {
    assert(
      _orderedKeys.length == _orderedKeys.toSet().length,
      "Two or more provided keys are identical. Each key must appear only once.",
    );
  }

  @override
  Iterable<LogicalKeyboardKey> get triggers => _triggers;
  late final Set<LogicalKeyboardKey> _triggers = _keySet
      .expand((key) => _unmapSynonyms[key] ?? <LogicalKeyboardKey>[key])
      .toSet();

  bool _checkKeyRequirements(Set<LogicalKeyboardKey> pressed) {
    final collapsedRequired = LogicalKeyboardKey.collapseSynonyms(_keySet);
    final collapsedPressed = LogicalKeyboardKey.collapseSynonyms(pressed);
    return collapsedRequired.length == collapsedPressed.length &&
        collapsedRequired.difference(collapsedPressed).isEmpty;
  }

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }
    return _triggers.contains(event.logicalKey) &&
        _checkKeyRequirements(state.logicalKeysPressed);
  }

  static final Map<LogicalKeyboardKey, List<LogicalKeyboardKey>>
  _unmapSynonyms = <LogicalKeyboardKey, List<LogicalKeyboardKey>>{
    LogicalKeyboardKey.control: <LogicalKeyboardKey>[
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
    ],
    LogicalKeyboardKey.shift: <LogicalKeyboardKey>[
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
    LogicalKeyboardKey.alt: <LogicalKeyboardKey>[
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
    ],
    LogicalKeyboardKey.meta: <LogicalKeyboardKey>[
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    ],
  };

  @override
  String debugDescribeKeys() {
    final displayKeys = List<LogicalKeyboardKey>.from(_orderedKeys);
    return displayKeys
        .map<String>((key) => key.debugName ?? key.toString())
        .join(" + ");
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<List<LogicalKeyboardKey>>(
        "orderedKeys",
        _orderedKeys,
        description: debugDescribeKeys(),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SortedLogicalKeyActivator &&
        setEquals<LogicalKeyboardKey>(other._keySet, _keySet);
  }

  @override
  int get hashCode => _computeOrderIndependentHash(_keySet);

  static final List<int> _tempHashStore3 = <int>[0, 0, 0];
  static final List<int> _tempHashStore4 = <int>[0, 0, 0, 0];

  static int _computeOrderIndependentHash(Set<LogicalKeyboardKey> keys) {
    final length = keys.length;
    final iterator = keys.iterator..moveNext();
    final h1 = iterator.current.hashCode;
    if (length == 1) {
      return h1;
    }
    iterator.moveNext();
    final h2 = iterator.current.hashCode;
    if (length == 2) {
      return h1 < h2 ? Object.hash(h1, h2) : Object.hash(h2, h1);
    }
    final sortedHashes = length == 3 ? _tempHashStore3 : _tempHashStore4;
    sortedHashes[0] = h1;
    sortedHashes[1] = h2;
    iterator.moveNext();
    sortedHashes[2] = iterator.current.hashCode;
    if (length == 4) {
      iterator.moveNext();
      sortedHashes[3] = iterator.current.hashCode;
    }
    sortedHashes.sort();
    return Object.hashAll(sortedHashes);
  }
}

extension ShortcutActivatorX on ShortcutActivator {
  List<LogicalKeyboardKey> get keys => switch (this) {
    SingleActivator(
      :final alt,
      :final control,
      :final meta,
      :final shift,
      :final trigger,
    ) =>
      [
        if (alt) LogicalKeyboardKey.alt,
        if (control) LogicalKeyboardKey.control,
        if (meta) LogicalKeyboardKey.meta,
        if (shift) LogicalKeyboardKey.shift,
        trigger,
      ],
    CharacterActivator(:final alt, :final control, :final meta) => [
      if (alt) LogicalKeyboardKey.alt,
      if (control) LogicalKeyboardKey.control,
      if (meta) LogicalKeyboardKey.meta,
    ],
    LogicalKeySet(:final keys) => keys.toList(),
    SortedLogicalKeyActivator(:final orderedKeys) => orderedKeys.toList(),
    _ => throw UnsupportedError("Unsupported shortcut type $runtimeType"),
  };

  int get length => keys.length;
}
