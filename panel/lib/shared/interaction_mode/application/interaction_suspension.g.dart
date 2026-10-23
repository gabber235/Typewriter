// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_suspension.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether mode shortcuts and selection operations are blocked app wide, for
/// example while the realm connection is being checked.
///
/// The app overrides it through appOverrides; the default keeps tests and
/// Widgetbook stories unblocked.

@ProviderFor(interactionSuspended)
final interactionSuspendedProvider = InteractionSuspendedProvider._();

/// Whether mode shortcuts and selection operations are blocked app wide, for
/// example while the realm connection is being checked.
///
/// The app overrides it through appOverrides; the default keeps tests and
/// Widgetbook stories unblocked.

final class InteractionSuspendedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether mode shortcuts and selection operations are blocked app wide, for
  /// example while the realm connection is being checked.
  ///
  /// The app overrides it through appOverrides; the default keeps tests and
  /// Widgetbook stories unblocked.
  InteractionSuspendedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interactionSuspendedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interactionSuspendedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return interactionSuspended(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$interactionSuspendedHash() =>
    r'f843bdcb68af9c4399aa9394ca5491eb0883683d';
