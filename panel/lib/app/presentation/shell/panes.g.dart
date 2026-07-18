// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'panes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Panes)
final panesProvider = PanesProvider._();

final class PanesProvider
    extends $NotifierProvider<Panes, Map<String, PaneInfo>> {
  PanesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'panesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$panesHash();

  @$internal
  @override
  Panes create() => Panes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, PaneInfo> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, PaneInfo>>(value),
    );
  }
}

String _$panesHash() => r'371815f309cdb7892c881ad29bc913cb4e92fa34';

abstract class _$Panes extends $Notifier<Map<String, PaneInfo>> {
  Map<String, PaneInfo> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, PaneInfo>, Map<String, PaneInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, PaneInfo>, Map<String, PaneInfo>>,
              Map<String, PaneInfo>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
