// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authoring_subjects.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves a whole visible resource scope under one exact catalog generation.
///
/// Dependency changes rebuild the provider with the current session sequence
/// and local draft snapshot. Riverpod discards completions from older builds,
/// so a late batch cannot replace a newer canonical or draft projection.

@ProviderFor(authoringSubjects)
final authoringSubjectsProvider = AuthoringSubjectsFamily._();

/// Resolves a whole visible resource scope under one exact catalog generation.
///
/// Dependency changes rebuild the provider with the current session sequence
/// and local draft snapshot. Riverpod discards completions from older builds,
/// so a late batch cannot replace a newer canonical or draft projection.

final class AuthoringSubjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringSubjectProjection>,
          AuthoringSubjectProjection,
          FutureOr<AuthoringSubjectProjection>
        >
    with
        $FutureModifier<AuthoringSubjectProjection>,
        $FutureProvider<AuthoringSubjectProjection> {
  /// Resolves a whole visible resource scope under one exact catalog generation.
  ///
  /// Dependency changes rebuild the provider with the current session sequence
  /// and local draft snapshot. Riverpod discards completions from older builds,
  /// so a late batch cannot replace a newer canonical or draft projection.
  AuthoringSubjectsProvider._({
    required AuthoringSubjectsFamily super.from,
    required AuthoringSubjectScope super.argument,
  }) : super(
         retry: null,
         name: r'authoringSubjectsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringSubjectsHash();

  @override
  String toString() {
    return r'authoringSubjectsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AuthoringSubjectProjection> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AuthoringSubjectProjection> create(Ref ref) {
    final argument = this.argument as AuthoringSubjectScope;
    return authoringSubjects(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringSubjectsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringSubjectsHash() => r'5c431a1397007566f01ce423edd2db0c36a28020';

/// Resolves a whole visible resource scope under one exact catalog generation.
///
/// Dependency changes rebuild the provider with the current session sequence
/// and local draft snapshot. Riverpod discards completions from older builds,
/// so a late batch cannot replace a newer canonical or draft projection.

final class AuthoringSubjectsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<AuthoringSubjectProjection>,
          AuthoringSubjectScope
        > {
  AuthoringSubjectsFamily._()
    : super(
        retry: null,
        name: r'authoringSubjectsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves a whole visible resource scope under one exact catalog generation.
  ///
  /// Dependency changes rebuild the provider with the current session sequence
  /// and local draft snapshot. Riverpod discards completions from older builds,
  /// so a late batch cannot replace a newer canonical or draft projection.

  AuthoringSubjectsProvider call(AuthoringSubjectScope scope) =>
      AuthoringSubjectsProvider._(argument: scope, from: this);

  @override
  String toString() => r'authoringSubjectsProvider';
}
