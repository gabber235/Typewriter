// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platforms_popup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(ProposedTargets)
const proposedTargetsProvider = ProposedTargetsFamily._();

final class ProposedTargetsProvider
    extends $AsyncNotifierProvider<ProposedTargets, List<PlatformTarget>> {
  const ProposedTargetsProvider._(
      {required ProposedTargetsFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'proposedTargetsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$proposedTargetsHash();

  @override
  String toString() {
    return r'proposedTargetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProposedTargets create() => ProposedTargets();

  @override
  bool operator ==(Object other) {
    return other is ProposedTargetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proposedTargetsHash() => r'd83cd234fb0c05608a127ceec0b815808c900b64';

final class ProposedTargetsFamily extends $Family
    with
        $ClassFamilyOverride<ProposedTargets, AsyncValue<List<PlatformTarget>>,
            List<PlatformTarget>, FutureOr<List<PlatformTarget>>, String> {
  const ProposedTargetsFamily._()
      : super(
          retry: null,
          name: r'proposedTargetsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ProposedTargetsProvider call(
    String manualId,
  ) =>
      ProposedTargetsProvider._(argument: manualId, from: this);

  @override
  String toString() => r'proposedTargetsProvider';
}

abstract class _$ProposedTargets extends $AsyncNotifier<List<PlatformTarget>> {
  late final _$args = ref.$arg as String;
  String get manualId => _$args;

  FutureOr<List<PlatformTarget>> build(
    String manualId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref = this.ref
        as $Ref<AsyncValue<List<PlatformTarget>>, List<PlatformTarget>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PlatformTarget>>, List<PlatformTarget>>,
        AsyncValue<List<PlatformTarget>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
