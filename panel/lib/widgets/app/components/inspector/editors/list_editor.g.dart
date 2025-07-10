// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(_listValueLength)
const _listValueLengthProvider = _ListValueLengthFamily._();

final class _ListValueLengthProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  const _ListValueLengthProvider._(
      {required _ListValueLengthFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'_listValueLengthProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$listValueLengthHash();

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
    return _listValueLength(
      ref,
      argument,
    );
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

String _$listValueLengthHash() => r'8ceeffa37d6f86207ba05ad7d0b99adb477fcf2f';

final class _ListValueLengthFamily extends $Family
    with $FunctionalFamilyOverride<int, String> {
  const _ListValueLengthFamily._()
      : super(
          retry: null,
          name: r'_listValueLengthProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  _ListValueLengthProvider call(
    String path,
  ) =>
      _ListValueLengthProvider._(argument: path, from: this);

  @override
  String toString() => r'_listValueLengthProvider';
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
