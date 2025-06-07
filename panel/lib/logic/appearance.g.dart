// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appearance.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(Appearance)
const appearanceProvider = AppearanceProvider._();

final class AppearanceProvider
    extends $NotifierProvider<Appearance, ThemeMode> {
  const AppearanceProvider._()
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

  @$internal
  @override
  $NotifierProviderElement<Appearance, ThemeMode> $createElement(
          $ProviderPointer pointer) =>
      $NotifierProviderElement(pointer);

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $ValueProvider<ThemeMode>(value),
    );
  }
}

String _$appearanceHash() => r'4395b770b6349e3dbcb7aeaf51bbbf4380085be8';

abstract class _$Appearance extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ThemeMode>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<ThemeMode>,
        ThemeMode, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
