// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Services)
const servicesProvider = ServicesProvider._();

final class ServicesProvider
    extends $StreamNotifierProvider<Services, List<Service>> {
  const ServicesProvider._()
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

String _$servicesHash() => r'e6a988e1759be7c3d7372e67f802a05554f2733d';

abstract class _$Services extends $StreamNotifier<List<Service>> {
  Stream<List<Service>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Service>>, List<Service>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Service>>, List<Service>>,
              AsyncValue<List<Service>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(service)
const serviceProvider = ServiceFamily._();

final class ServiceProvider
    extends
        $FunctionalProvider<AsyncValue<Service?>, Service?, FutureOr<Service?>>
    with $FutureModifier<Service?>, $FutureProvider<Service?> {
  const ServiceProvider._({
    required ServiceFamily super.from,
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$serviceHash() => r'733a3e79fd93f72b899b5187c08646c59422cbbd';

final class ServiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Service?>, String> {
  const ServiceFamily._()
    : super(
        retry: null,
        name: r'serviceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ServiceProvider call(String id) =>
      ServiceProvider._(argument: id, from: this);

  @override
  String toString() => r'serviceProvider';
}
