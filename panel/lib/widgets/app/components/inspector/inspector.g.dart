// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(InspectorSize)
const inspectorSizeProvider = InspectorSizeProvider._();

final class InspectorSizeProvider
    extends $NotifierProvider<InspectorSize, double> {
  const InspectorSizeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'inspectorSizeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$inspectorSizeHash();

  @$internal
  @override
  InspectorSize create() => InspectorSize();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$inspectorSizeHash() => r'32cb9e3db4598af8e9632d80da936509ced2573d';

abstract class _$InspectorSize extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<double, double>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<double, double>, double, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
