// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the sentinel credentials from the API.

@ProviderFor(sentinelCredentials)
final sentinelCredentialsProvider = SentinelCredentialsProvider._();

/// Fetches the sentinel credentials from the API.

final class SentinelCredentialsProvider
    extends
        $FunctionalProvider<
          AsyncValue<GetSentinelCredentialsResponse_Success>,
          GetSentinelCredentialsResponse_Success,
          FutureOr<GetSentinelCredentialsResponse_Success>
        >
    with
        $FutureModifier<GetSentinelCredentialsResponse_Success>,
        $FutureProvider<GetSentinelCredentialsResponse_Success> {
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
  $FutureProviderElement<GetSentinelCredentialsResponse_Success> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GetSentinelCredentialsResponse_Success> create(Ref ref) {
    return sentinelCredentials(ref);
  }
}

String _$sentinelCredentialsHash() =>
    r'0a4b52f5afd13a63f9b80d01adadeac9d3e64396';

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

String _$natsHash() => r'73b21231aa557b277ce2d8f84e6cca2d6c147748';

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
