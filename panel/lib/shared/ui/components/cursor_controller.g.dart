// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the application cursor override used by pointer driven interactions.
///
/// The provider state is the cursor applied by [GlobalCursorController]. Call
/// [cursor] while an interaction is active and [reset] when it releases the
/// pointer.

@ProviderFor(CursorController)
final cursorControllerProvider = CursorControllerProvider._();

/// Owns the application cursor override used by pointer driven interactions.
///
/// The provider state is the cursor applied by [GlobalCursorController]. Call
/// [cursor] while an interaction is active and [reset] when it releases the
/// pointer.
final class CursorControllerProvider
    extends $NotifierProvider<CursorController, MouseCursor> {
  /// Owns the application cursor override used by pointer driven interactions.
  ///
  /// The provider state is the cursor applied by [GlobalCursorController]. Call
  /// [cursor] while an interaction is active and [reset] when it releases the
  /// pointer.
  CursorControllerProvider._()
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

/// Owns the application cursor override used by pointer driven interactions.
///
/// The provider state is the cursor applied by [GlobalCursorController]. Call
/// [cursor] while an interaction is active and [reset] when it releases the
/// pointer.

abstract class _$CursorController extends $Notifier<MouseCursor> {
  MouseCursor build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MouseCursor, MouseCursor>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MouseCursor, MouseCursor>,
              MouseCursor,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
