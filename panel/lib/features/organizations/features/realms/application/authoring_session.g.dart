// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authoring_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthoringSession)
final authoringSessionProvider = AuthoringSessionFamily._();

final class AuthoringSessionProvider
    extends $NotifierProvider<AuthoringSession, AuthoringSessionState> {
  AuthoringSessionProvider._({
    required AuthoringSessionFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'authoringSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringSessionHash();

  @override
  String toString() {
    return r'authoringSessionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AuthoringSession create() => AuthoringSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringSessionHash() => r'7d0ad86e28505e701c8240dbbc8b523c3e72e8f1';

final class AuthoringSessionFamily extends $Family
    with
        $ClassFamilyOverride<
          AuthoringSession,
          AuthoringSessionState,
          AuthoringSessionState,
          AuthoringSessionState,
          (skir.RecordId, skir.RecordId)
        > {
  AuthoringSessionFamily._()
    : super(
        retry: null,
        name: r'authoringSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthoringSessionProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => AuthoringSessionProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'authoringSessionProvider';
}

abstract class _$AuthoringSession extends $Notifier<AuthoringSessionState> {
  late final _$args = ref.$arg as (skir.RecordId, skir.RecordId);
  skir.RecordId get organizationId => _$args.$1;
  skir.RecordId get realmId => _$args.$2;

  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthoringSessionState, AuthoringSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthoringSessionState, AuthoringSessionState>,
              AuthoringSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
