// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InspectorSize)
final inspectorSizeProvider = InspectorSizeProvider._();

final class InspectorSizeProvider
    extends $NotifierProvider<InspectorSize, double> {
  InspectorSizeProvider._()
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

String _$inspectorSizeHash() => r'bdbec34c18631cd20a79204c6038b93ebb5d4a82';

abstract class _$InspectorSize extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
