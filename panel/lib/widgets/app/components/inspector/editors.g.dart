// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editors.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(editors)
const editorsProvider = EditorsProvider._();

final class EditorsProvider
    extends $FunctionalProvider<List<Editor>, List<Editor>, List<Editor>>
    with $Provider<List<Editor>> {
  const EditorsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'editorsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$editorsHash();

  @$internal
  @override
  $ProviderElement<List<Editor>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Editor> create(Ref ref) {
    return editors(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Editor> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Editor>>(value),
    );
  }
}

String _$editorsHash() => r'f38c2fef4a7bd1f699db349b377d5b461eeacde4';

@ProviderFor(pathDisplayName)
const pathDisplayNameProvider = PathDisplayNameFamily._();

final class PathDisplayNameProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  const PathDisplayNameProvider._(
      {required PathDisplayNameFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'pathDisplayNameProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pathDisplayNameHash();

  @override
  String toString() {
    return r'pathDisplayNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    final argument = this.argument as String;
    return pathDisplayName(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PathDisplayNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pathDisplayNameHash() => r'4cb4a7c76014fdfb5b467087fff861b000a9b4f2';

final class PathDisplayNameFamily extends $Family
    with $FunctionalFamilyOverride<String, String> {
  const PathDisplayNameFamily._()
      : super(
          retry: null,
          name: r'pathDisplayNameProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PathDisplayNameProvider call(
    String path,
  ) =>
      PathDisplayNameProvider._(argument: path, from: this);

  @override
  String toString() => r'pathDisplayNameProvider';
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
