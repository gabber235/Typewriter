// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Services)
final servicesProvider = ServicesProvider._();

final class ServicesProvider
    extends $StreamNotifierProvider<Services, List<Service>> {
  ServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicesHash();

  @$internal
  @override
  Services create() => Services();
}

String _$servicesHash() => r'a12701dd25ab76fb97dc8a8ebdc18fb3c45dadf0';

abstract class _$Services extends $StreamNotifier<List<Service>> {
  Stream<List<Service>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Service>>, List<Service>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Service>>, List<Service>>,
              AsyncValue<List<Service>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(service)
final serviceProvider = ServiceFamily._();

final class ServiceProvider
    extends
        $FunctionalProvider<AsyncValue<Service?>, Service?, FutureOr<Service?>>
    with $FutureModifier<Service?>, $FutureProvider<Service?> {
  ServiceProvider._({
    required ServiceFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'serviceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceHash();

  @override
  String toString() {
    return r'serviceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Service?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Service?> create(Ref ref) {
    final argument = this.argument as skir.RecordId;
    return service(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceHash() => r'3c409075a9fd560b0622bb74b06d4c0b1450d092';

final class ServiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Service?>, skir.RecordId> {
  ServiceFamily._()
    : super(
        retry: null,
        name: r'serviceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ServiceProvider call(skir.RecordId id) =>
      ServiceProvider._(argument: id, from: this);

  @override
  String toString() => r'serviceProvider';
}
