// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(CursorController)
const cursorControllerProvider = CursorControllerProvider._();

final class CursorControllerProvider
    extends $NotifierProvider<CursorController, SystemMouseCursor> {
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
  Override overrideWithValue(SystemMouseCursor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemMouseCursor>(value),
    );
  }
}

String _$cursorControllerHash() => r'aa98d03ba548eb36430d4f4e747ab4cad27d4241';

abstract class _$CursorController extends $Notifier<SystemMouseCursor> {
  SystemMouseCursor build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SystemMouseCursor, SystemMouseCursor>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SystemMouseCursor, SystemMouseCursor>,
        SystemMouseCursor,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
