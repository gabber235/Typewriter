// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$natsHash() => r'd79dc3b9da5b2b2f3ccce90a70675211504599bd';

/// See also [Nats].
@ProviderFor(Nats)
final natsProvider = NotifierProvider<Nats, Client>.internal(
  Nats.new,
  name: r'natsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$natsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Nats = Notifier<Client>;
String _$natsStatusHash() => r'01597be429d7e0b9cd3acf4ddf29582d96174e0b';

/// See also [NatsStatus].
@ProviderFor(NatsStatus)
final natsStatusProvider =
    AutoDisposeNotifierProvider<NatsStatus, Status>.internal(
  NatsStatus.new,
  name: r'natsStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$natsStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NatsStatus = AutoDisposeNotifier<Status>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
