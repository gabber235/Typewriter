// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(Nats)
const natsProvider = NatsProvider._();

final class NatsProvider extends $NotifierProvider<Nats, Client> {
  const NatsProvider._()
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

  @$internal
  @override
  $NotifierProviderElement<Nats, Client> $createElement(
          $ProviderPointer pointer) =>
      $NotifierProviderElement(pointer);

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $ValueProvider<Client>(value),
    );
  }
}

String _$natsHash() => r'e2f1d580a35bd9a586abfa0152e0dd0ef7af069b';

abstract class _$Nats extends $Notifier<Client> {
  Client build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Client>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<Client>, Client, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(NatsStatus)
const natsStatusProvider = NatsStatusProvider._();

final class NatsStatusProvider extends $NotifierProvider<NatsStatus, Status> {
  const NatsStatusProvider._()
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

  @$internal
  @override
  $NotifierProviderElement<NatsStatus, Status> $createElement(
          $ProviderPointer pointer) =>
      $NotifierProviderElement(pointer);

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Status value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $ValueProvider<Status>(value),
    );
  }
}

String _$natsStatusHash() => r'01597be429d7e0b9cd3acf4ddf29582d96174e0b';

abstract class _$NatsStatus extends $Notifier<Status> {
  Status build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Status>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<Status>, Status, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
