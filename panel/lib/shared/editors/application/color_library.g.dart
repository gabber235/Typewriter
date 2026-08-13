// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(colorLibraryStorage)
final colorLibraryStorageProvider = ColorLibraryStorageProvider._();

final class ColorLibraryStorageProvider
    extends
        $FunctionalProvider<
          ColorLibraryStorage,
          ColorLibraryStorage,
          ColorLibraryStorage
        >
    with $Provider<ColorLibraryStorage> {
  ColorLibraryStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'colorLibraryStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$colorLibraryStorageHash();

  @$internal
  @override
  $ProviderElement<ColorLibraryStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ColorLibraryStorage create(Ref ref) {
    return colorLibraryStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ColorLibraryStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ColorLibraryStorage>(value),
    );
  }
}

String _$colorLibraryStorageHash() =>
    r'0408e37522c083a862c009f22f413fedd7abe992';

@ProviderFor(ColorLibrary)
final colorLibraryProvider = ColorLibraryProvider._();

final class ColorLibraryProvider
    extends $NotifierProvider<ColorLibrary, ColorLibraryState> {
  ColorLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'colorLibraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$colorLibraryHash();

  @$internal
  @override
  ColorLibrary create() => ColorLibrary();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ColorLibraryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ColorLibraryState>(value),
    );
  }
}

String _$colorLibraryHash() => r'8788e37ab37d27b64e7b8c4e9077661191d69777';

abstract class _$ColorLibrary extends $Notifier<ColorLibraryState> {
  ColorLibraryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ColorLibraryState, ColorLibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ColorLibraryState, ColorLibraryState>,
              ColorLibraryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
