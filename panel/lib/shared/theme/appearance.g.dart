// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appearance.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stores the panel's theme preference and exposes it to the application shell.
///
/// The preference is read from browser or platform storage when the provider is
/// first built. [mode] updates both storage and the provider state so the shell
/// changes theme immediately and keeps the choice for the next launch.

@ProviderFor(Appearance)
final appearanceProvider = AppearanceProvider._();

/// Stores the panel's theme preference and exposes it to the application shell.
///
/// The preference is read from browser or platform storage when the provider is
/// first built. [mode] updates both storage and the provider state so the shell
/// changes theme immediately and keeps the choice for the next launch.
final class AppearanceProvider
    extends $NotifierProvider<Appearance, ThemeMode> {
  /// Stores the panel's theme preference and exposes it to the application shell.
  ///
  /// The preference is read from browser or platform storage when the provider is
  /// first built. [mode] updates both storage and the provider state so the shell
  /// changes theme immediately and keeps the choice for the next launch.
  AppearanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appearanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appearanceHash();

  @$internal
  @override
  Appearance create() => Appearance();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appearanceHash() => r'4395b770b6349e3dbcb7aeaf51bbbf4380085be8';

/// Stores the panel's theme preference and exposes it to the application shell.
///
/// The preference is read from browser or platform storage when the provider is
/// first built. [mode] updates both storage and the provider state so the shell
/// changes theme immediately and keeps the choice for the next launch.

abstract class _$Appearance extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
