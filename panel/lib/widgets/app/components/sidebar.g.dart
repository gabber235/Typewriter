// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sidebar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SidebarSize)
const sidebarSizeProvider = SidebarSizeProvider._();

final class SidebarSizeProvider extends $NotifierProvider<SidebarSize, double> {
  const SidebarSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sidebarSizeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sidebarSizeHash();

  @$internal
  @override
  SidebarSize create() => SidebarSize();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$sidebarSizeHash() => r'e2cd1957407902676e146d6e808ab72e21cb2d5d';

abstract class _$SidebarSize extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
