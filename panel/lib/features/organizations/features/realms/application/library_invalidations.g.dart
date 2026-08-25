// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_invalidations.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(libraryInvalidations)
final libraryInvalidationsProvider = LibraryInvalidationsFamily._();

final class LibraryInvalidationsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  LibraryInvalidationsProvider._({
    required LibraryInvalidationsFamily super.from,
    required skir.LibraryResourceKind super.argument,
  }) : super(
         retry: null,
         name: r'libraryInvalidationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryInvalidationsHash();

  @override
  String toString() {
    return r'libraryInvalidationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as skir.LibraryResourceKind;
    return libraryInvalidations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryInvalidationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryInvalidationsHash() =>
    r'02dbf6843520ed2de9ca85d34bef8a74fc6e228a';

final class LibraryInvalidationsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, skir.LibraryResourceKind> {
  LibraryInvalidationsFamily._()
    : super(
        retry: null,
        name: r'libraryInvalidationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LibraryInvalidationsProvider call(skir.LibraryResourceKind resource) =>
      LibraryInvalidationsProvider._(argument: resource, from: this);

  @override
  String toString() => r'libraryInvalidationsProvider';
}
