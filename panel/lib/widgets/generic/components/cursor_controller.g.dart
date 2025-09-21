// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CursorController)
const cursorControllerProvider = CursorControllerProvider._();

final class CursorControllerProvider
    extends $NotifierProvider<CursorController, MouseCursor> {
  const CursorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cursorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cursorControllerHash();

  @$internal
  @override
  CursorController create() => CursorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MouseCursor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MouseCursor>(value),
    );
  }
}

String _$cursorControllerHash() => r'577c9578298737af12511c355955b665038646ea';

abstract class _$CursorController extends $Notifier<MouseCursor> {
  MouseCursor build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MouseCursor, MouseCursor>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MouseCursor, MouseCursor>,
              MouseCursor,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
