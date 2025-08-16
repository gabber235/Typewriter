// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modules_popup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ManualModuleInformation _$ManualModuleInformationFromJson(
        Map<String, dynamic> json) =>
    _ManualModuleInformation(
      moduleId: json['moduleId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      type: $enumDecode(_$ModuleTypeEnumMap, json['type']),
      version: const SemverJsonConverter().fromJson(json['version']),
      compatibleVersions: const SemverListJsonConverter()
          .fromJson(json['compatibleVersions'] as List),
      canBeRemoved: json['canBeRemoved'] as bool? ?? true,
    );

Map<String, dynamic> _$ManualModuleInformationToJson(
        _ManualModuleInformation instance) =>
    <String, dynamic>{
      'moduleId': instance.moduleId,
      'name': instance.name,
      'description': instance.description,
      'author': instance.author,
      'type': _$ModuleTypeEnumMap[instance.type]!,
      'version': const SemverJsonConverter().toJson(instance.version),
      'compatibleVersions':
          const SemverListJsonConverter().toJson(instance.compatibleVersions),
      'canBeRemoved': instance.canBeRemoved,
    };

const _$ModuleTypeEnumMap = {
  ModuleType.engine: 'engine',
  ModuleType.extension: 'extension',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(ProposedModules)
const proposedModulesProvider = ProposedModulesFamily._();

final class ProposedModulesProvider extends $AsyncNotifierProvider<
    ProposedModules, List<ManualModuleReference>> {
  const ProposedModulesProvider._(
      {required ProposedModulesFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'proposedModulesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$proposedModulesHash();

  @override
  String toString() {
    return r'proposedModulesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProposedModules create() => ProposedModules();

  @override
  bool operator ==(Object other) {
    return other is ProposedModulesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proposedModulesHash() => r'dbf438baaf9cf9d43c9f299ae8158780b3f2410e';

final class ProposedModulesFamily extends $Family
    with
        $ClassFamilyOverride<
            ProposedModules,
            AsyncValue<List<ManualModuleReference>>,
            List<ManualModuleReference>,
            FutureOr<List<ManualModuleReference>>,
            String> {
  const ProposedModulesFamily._()
      : super(
          retry: null,
          name: r'proposedModulesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ProposedModulesProvider call(
    String manualId,
  ) =>
      ProposedModulesProvider._(argument: manualId, from: this);

  @override
  String toString() => r'proposedModulesProvider';
}

abstract class _$ProposedModules
    extends $AsyncNotifier<List<ManualModuleReference>> {
  late final _$args = ref.$arg as String;
  String get manualId => _$args;

  FutureOr<List<ManualModuleReference>> build(
    String manualId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref = this.ref as $Ref<AsyncValue<List<ManualModuleReference>>,
        List<ManualModuleReference>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<ManualModuleReference>>,
            List<ManualModuleReference>>,
        AsyncValue<List<ManualModuleReference>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ProposedModulesIds)
const proposedModulesIdsProvider = ProposedModulesIdsFamily._();

final class ProposedModulesIdsProvider
    extends $AsyncNotifierProvider<ProposedModulesIds, List<String>> {
  const ProposedModulesIdsProvider._(
      {required ProposedModulesIdsFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'proposedModulesIdsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$proposedModulesIdsHash();

  @override
  String toString() {
    return r'proposedModulesIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProposedModulesIds create() => ProposedModulesIds();

  @override
  bool operator ==(Object other) {
    return other is ProposedModulesIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proposedModulesIdsHash() =>
    r'57a4b639b6de1e8f8f0b095405f782a4e0067a6e';

final class ProposedModulesIdsFamily extends $Family
    with
        $ClassFamilyOverride<ProposedModulesIds, AsyncValue<List<String>>,
            List<String>, FutureOr<List<String>>, String> {
  const ProposedModulesIdsFamily._()
      : super(
          retry: null,
          name: r'proposedModulesIdsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ProposedModulesIdsProvider call(
    String manualId,
  ) =>
      ProposedModulesIdsProvider._(argument: manualId, from: this);

  @override
  String toString() => r'proposedModulesIdsProvider';
}

abstract class _$ProposedModulesIds extends $AsyncNotifier<List<String>> {
  late final _$args = ref.$arg as String;
  String get manualId => _$args;

  FutureOr<List<String>> build(
    String manualId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<String>>, List<String>>,
        AsyncValue<List<String>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(manualModulesInfo)
const manualModulesInfoProvider = ManualModulesInfoFamily._();

final class ManualModulesInfoProvider extends $FunctionalProvider<
        AsyncValue<List<ManualModuleInformation>>,
        List<ManualModuleInformation>,
        FutureOr<List<ManualModuleInformation>>>
    with
        $FutureModifier<List<ManualModuleInformation>>,
        $FutureProvider<List<ManualModuleInformation>> {
  const ManualModulesInfoProvider._(
      {required ManualModulesInfoFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'manualModulesInfoProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$manualModulesInfoHash();

  @override
  String toString() {
    return r'manualModulesInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ManualModuleInformation>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<ManualModuleInformation>> create(Ref ref) {
    final argument = this.argument as String;
    return manualModulesInfo(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ManualModulesInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualModulesInfoHash() => r'249ef57a9f4ca25a5de88a73fd759d43fd0b7f09';

final class ManualModulesInfoFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<ManualModuleInformation>>,
            String> {
  const ManualModulesInfoFamily._()
      : super(
          retry: null,
          name: r'manualModulesInfoProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ManualModulesInfoProvider call(
    String manualId,
  ) =>
      ManualModulesInfoProvider._(argument: manualId, from: this);

  @override
  String toString() => r'manualModulesInfoProvider';
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
