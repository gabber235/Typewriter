// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sidebar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the sidebar width used by desktop layout and keyboard resizing.
///
/// The provider starts at [kSidebarDefaultSize]. Calls to [size] enforce the
/// global minimum; the controller applies the viewport specific maximum before
/// writing a value here.

@ProviderFor(SidebarSize)
final sidebarSizeProvider = SidebarSizeProvider._();

/// Owns the sidebar width used by desktop layout and keyboard resizing.
///
/// The provider starts at [kSidebarDefaultSize]. Calls to [size] enforce the
/// global minimum; the controller applies the viewport specific maximum before
/// writing a value here.
final class SidebarSizeProvider extends $NotifierProvider<SidebarSize, double> {
  /// Owns the sidebar width used by desktop layout and keyboard resizing.
  ///
  /// The provider starts at [kSidebarDefaultSize]. Calls to [size] enforce the
  /// global minimum; the controller applies the viewport specific maximum before
  /// writing a value here.
  SidebarSizeProvider._()
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

/// Owns the sidebar width used by desktop layout and keyboard resizing.
///
/// The provider starts at [kSidebarDefaultSize]. Calls to [size] enforce the
/// global minimum; the controller applies the viewport specific maximum before
/// writing a value here.

abstract class _$SidebarSize extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
