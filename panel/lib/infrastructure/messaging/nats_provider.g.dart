// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'nats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
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

@ProviderFor(natsConnectionSessionFactory)
final natsConnectionSessionFactoryProvider =
    NatsConnectionSessionFactoryProvider._();

final class NatsConnectionSessionFactoryProvider
    extends
        $FunctionalProvider<
          NatsConnectionSessionFactory,
          NatsConnectionSessionFactory,
          NatsConnectionSessionFactory
        >
    with $Provider<NatsConnectionSessionFactory> {
  NatsConnectionSessionFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'natsConnectionSessionFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$natsConnectionSessionFactoryHash();

  @$internal
  @override
  $ProviderElement<NatsConnectionSessionFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NatsConnectionSessionFactory create(Ref ref) {
    return natsConnectionSessionFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NatsConnectionSessionFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NatsConnectionSessionFactory>(value),
    );
  }
}

String _$natsConnectionSessionFactoryHash() =>
    r'efc56a1ff506ce661dee48cb9753c38de71ef235';

/// Owns the HTTP client used by panel infrastructure requests.

@ProviderFor(panelHttpClient)
final panelHttpClientProvider = PanelHttpClientProvider._();

/// Owns the HTTP client used by panel infrastructure requests.

final class PanelHttpClientProvider
    extends $FunctionalProvider<Client, Client, Client>
    with $Provider<Client> {
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
  $ProviderElement<Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Client create(Ref ref) {
    return panelHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Client>(value),
    );
  }
}

String _$panelHttpClientHash() => r'e19c3ba3e7d607f78da40a62ede3db9221f54206';

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

/// Publishes the active client owned by the authenticated connection scope.
///
/// Credential and organization changes dispose the entire previous connection.
/// Permission refresh and retry retain the current client until a replacement
/// has been admitted by the server.

@ProviderFor(Nats)
final natsProvider = NatsProvider._();

/// Publishes the active client owned by the authenticated connection scope.
///
/// Credential and organization changes dispose the entire previous connection.
/// Permission refresh and retry retain the current client until a replacement
/// has been admitted by the server.
final class NatsProvider extends $NotifierProvider<Nats, NatsClient> {
  /// Publishes the active client owned by the authenticated connection scope.
  ///
  /// Credential and organization changes dispose the entire previous connection.
  /// Permission refresh and retry retain the current client until a replacement
  /// has been admitted by the server.
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

String _$natsHash() => r'e9d6f3ac768a4bbe52579c7be177e8e2c9605b7c';

/// Publishes the active client owned by the authenticated connection scope.
///
/// Credential and organization changes dispose the entire previous connection.
/// Permission refresh and retry retain the current client until a replacement
/// has been admitted by the server.

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
