// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_listValueLength)
final _listValueLengthProvider = _ListValueLengthFamily._();

final class _ListValueLengthProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  _ListValueLengthProvider._({
    required _ListValueLengthFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'_listValueLengthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_listValueLengthHash();

  @override
  String toString() {
    return r'_listValueLengthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as String;
    return _listValueLength(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _ListValueLengthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_listValueLengthHash() => r'cf7ff608ba031adbc53f23c2985c0b424e0ab1f3';

final class _ListValueLengthFamily extends $Family
    with $FunctionalFamilyOverride<int, String> {
  _ListValueLengthFamily._()
    : super(
        retry: null,
        name: r'_listValueLengthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _ListValueLengthProvider call(String path) =>
      _ListValueLengthProvider._(argument: path, from: this);

  @override
  String toString() => r'_listValueLengthProvider';
}
