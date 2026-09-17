// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the concrete NATS owner factory used after authentication.

@ProviderFor(natsClientFactory)
final natsClientFactoryProvider = NatsClientFactoryProvider._();

/// Provides the concrete NATS owner factory used after authentication.

final class NatsClientFactoryProvider
    extends
        $FunctionalProvider<
          NatsClientFactory,
          NatsClientFactory,
          NatsClientFactory
        >
    with $Provider<NatsClientFactory> {
  /// Provides the concrete NATS owner factory used after authentication.
  NatsClientFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'natsClientFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$natsClientFactoryHash();

  @$internal
  @override
  $ProviderElement<NatsClientFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NatsClientFactory create(Ref ref) {
    return natsClientFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NatsClientFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NatsClientFactory>(value),
    );
  }
}

String _$natsClientFactoryHash() => r'1c0582e7a874e091f3f55ad289b386b471ca7651';

/// Owns the HTTP client used by panel infrastructure requests.

@ProviderFor(panelHttpClient)
final panelHttpClientProvider = PanelHttpClientProvider._();

/// Owns the HTTP client used by panel infrastructure requests.

final class PanelHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// Owns the HTTP client used by panel infrastructure requests.
  PanelHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'panelHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$panelHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return panelHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$panelHttpClientHash() => r'7135e3872b268ca83f0cf2cb03ecc737f66a43d1';

/// Fetches the short lived credentials required to open the user's NATS session.
///
/// HTTP status and unknown Skir variants are translated here, at the boundary
/// that still understands both the HTTP response and the generated contract.

@ProviderFor(sentinelCredentials)
final sentinelCredentialsProvider = SentinelCredentialsProvider._();

/// Fetches the short lived credentials required to open the user's NATS session.
///
/// HTTP status and unknown Skir variants are translated here, at the boundary
/// that still understands both the HTTP response and the generated contract.

final class SentinelCredentialsProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.GetSentinelCredentialsResponse_Success>,
          skir.GetSentinelCredentialsResponse_Success,
          FutureOr<skir.GetSentinelCredentialsResponse_Success>
        >
    with
        $FutureModifier<skir.GetSentinelCredentialsResponse_Success>,
        $FutureProvider<skir.GetSentinelCredentialsResponse_Success> {
  /// Fetches the short lived credentials required to open the user's NATS session.
  ///
  /// HTTP status and unknown Skir variants are translated here, at the boundary
  /// that still understands both the HTTP response and the generated contract.
  SentinelCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sentinelCredentialsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sentinelCredentialsHash();

  @$internal
  @override
  $FutureProviderElement<skir.GetSentinelCredentialsResponse_Success>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<skir.GetSentinelCredentialsResponse_Success> create(Ref ref) {
    return sentinelCredentials(ref);
  }
}

String _$sentinelCredentialsHash() =>
    r'd9ee71cee1fde6104af98ba3f2095b6144815fd6';

/// Owns the authenticated NATS client for the current user and organization.
///
/// Credential providers and the organization qualifier are read when this
/// owner is built. Invalidating it closes the old client before a fresh
/// connection is created, which makes retry an ownership operation rather than
/// a second connection layered over the first.

@ProviderFor(Nats)
final natsProvider = NatsProvider._();

/// Owns the authenticated NATS client for the current user and organization.
///
/// Credential providers and the organization qualifier are read when this
/// owner is built. Invalidating it closes the old client before a fresh
/// connection is created, which makes retry an ownership operation rather than
/// a second connection layered over the first.
final class NatsProvider extends $NotifierProvider<Nats, NatsClient> {
  /// Owns the authenticated NATS client for the current user and organization.
  ///
  /// Credential providers and the organization qualifier are read when this
  /// owner is built. Invalidating it closes the old client before a fresh
  /// connection is created, which makes retry an ownership operation rather than
  /// a second connection layered over the first.
  NatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'natsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$natsHash();

  @$internal
  @override
  Nats create() => Nats();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NatsClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NatsClient>(value),
    );
  }
}

String _$natsHash() => r'4ba08fe612ce973633013ce67e9af3211661997e';

/// Owns the authenticated NATS client for the current user and organization.
///
/// Credential providers and the organization qualifier are read when this
/// owner is built. Invalidating it closes the old client before a fresh
/// connection is created, which makes retry an ownership operation rather than
/// a second connection layered over the first.

abstract class _$Nats extends $Notifier<NatsClient> {
  NatsClient build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NatsClient, NatsClient>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NatsClient, NatsClient>,
              NatsClient,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Projects transport lifecycle into Riverpod for connection status UI.
///
/// The synchronous client state is emitted first, then later transport events
/// update the provider. This provider observes lifecycle only and does not own
/// the client or decide whether a failure is recoverable.

@ProviderFor(NatsLifecycle)
final natsLifecycleProvider = NatsLifecycleProvider._();

/// Projects transport lifecycle into Riverpod for connection status UI.
///
/// The synchronous client state is emitted first, then later transport events
/// update the provider. This provider observes lifecycle only and does not own
/// the client or decide whether a failure is recoverable.
final class NatsLifecycleProvider
    extends $NotifierProvider<NatsLifecycle, NatsConnectionState> {
  /// Projects transport lifecycle into Riverpod for connection status UI.
  ///
  /// The synchronous client state is emitted first, then later transport events
  /// update the provider. This provider observes lifecycle only and does not own
  /// the client or decide whether a failure is recoverable.
  NatsLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'natsLifecycleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$natsLifecycleHash();

  @$internal
  @override
  NatsLifecycle create() => NatsLifecycle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NatsConnectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NatsConnectionState>(value),
    );
  }
}

String _$natsLifecycleHash() => r'ebd1432b5da4db9d6ddf3c83acbd23bf33b8f31f';

/// Projects transport lifecycle into Riverpod for connection status UI.
///
/// The synchronous client state is emitted first, then later transport events
/// update the provider. This provider observes lifecycle only and does not own
/// the client or decide whether a failure is recoverable.

abstract class _$NatsLifecycle extends $Notifier<NatsConnectionState> {
  NatsConnectionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NatsConnectionState, NatsConnectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NatsConnectionState, NatsConnectionState>,
              NatsConnectionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
