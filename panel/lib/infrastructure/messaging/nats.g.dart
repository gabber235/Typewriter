// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(panelHttpClient)
final panelHttpClientProvider = PanelHttpClientProvider._();

final class PanelHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
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

/// Fetches the sentinel credentials from the API.

@ProviderFor(sentinelCredentials)
final sentinelCredentialsProvider = SentinelCredentialsProvider._();

/// Fetches the sentinel credentials from the API.

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
  /// Fetches the sentinel credentials from the API.
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

@ProviderFor(Nats)
final natsProvider = NatsProvider._();

final class NatsProvider extends $NotifierProvider<Nats, Client> {
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
  Override overrideWithValue(Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Client>(value),
    );
  }
}

String _$natsHash() => r'a9bd99853a183cfa59a85f73fd3e8266e7c3814b';

abstract class _$Nats extends $Notifier<Client> {
  Client build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Client, Client>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Client, Client>,
              Client,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(NatsStatus)
final natsStatusProvider = NatsStatusProvider._();

final class NatsStatusProvider extends $NotifierProvider<NatsStatus, Status> {
  NatsStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'natsStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$natsStatusHash();

  @$internal
  @override
  NatsStatus create() => NatsStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Status value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Status>(value),
    );
  }
}

String _$natsStatusHash() => r'01597be429d7e0b9cd3acf4ddf29582d96174e0b';

abstract class _$NatsStatus extends $Notifier<Status> {
  Status build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Status, Status>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Status, Status>,
              Status,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
