// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icon_library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IconLibrary)
final iconLibraryProvider = IconLibraryProvider._();

final class IconLibraryProvider
    extends $NotifierProvider<IconLibrary, List<String>> {
  IconLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iconLibraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iconLibraryHash();

  @$internal
  @override
  IconLibrary create() => IconLibrary();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$iconLibraryHash() => r'92dc07caa2096afe1f7dbc0155e142a64b6e03bc';

abstract class _$IconLibrary extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
