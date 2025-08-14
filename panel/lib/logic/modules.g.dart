// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Module _$ModuleFromJson(Map<String, dynamic> json) => _Module(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: $enumDecode(_$ModuleKindEnumMap, json['kind']),
      shortDescription: json['shortDescription'] as String? ?? "",
      versions: (json['versions'] as List<dynamic>?)
              ?.map((e) => ModuleVersion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ModuleVersion>[],
    );

Map<String, dynamic> _$ModuleToJson(_Module instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$ModuleKindEnumMap[instance.kind]!,
      'shortDescription': instance.shortDescription,
      'versions': instance.versions.map((e) => e.toJson()).toList(),
    };

const _$ModuleKindEnumMap = {
  ModuleKind.engine: 'engine',
  ModuleKind.extension: 'extension',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// Provides the list of available modules (engines + extensions).
@ProviderFor(Modules)
const modulesProvider = ModulesProvider._();

/// Provides the list of available modules (engines + extensions).
final class ModulesProvider
    extends $AsyncNotifierProvider<Modules, List<Module>> {
  /// Provides the list of available modules (engines + extensions).
  const ModulesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'modulesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$modulesHash();

  @$internal
  @override
  Modules create() => Modules();
}

String _$modulesHash() => r'a45fe53577f8dfd90bf6f4e0d421e3fee8552ce2';

abstract class _$Modules extends $AsyncNotifier<List<Module>> {
  FutureOr<List<Module>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Module>>, List<Module>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Module>>, List<Module>>,
        AsyncValue<List<Module>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

/// Filtered modules by (case-insensitive) query against name and tags (future).
@ProviderFor(filteredModules)
const filteredModulesProvider = FilteredModulesFamily._();

/// Filtered modules by (case-insensitive) query against name and tags (future).
final class FilteredModulesProvider extends $FunctionalProvider<
        AsyncValue<List<Module>>, List<Module>, FutureOr<List<Module>>>
    with $FutureModifier<List<Module>>, $FutureProvider<List<Module>> {
  /// Filtered modules by (case-insensitive) query against name and tags (future).
  const FilteredModulesProvider._(
      {required FilteredModulesFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'filteredModulesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$filteredModulesHash();

  @override
  String toString() {
    return r'filteredModulesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Module>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Module>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredModules(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredModulesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredModulesHash() => r'627cfd3343693f1126084e587b80a13568cf4066';

/// Filtered modules by (case-insensitive) query against name and tags (future).
final class FilteredModulesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Module>>, String> {
  const FilteredModulesFamily._()
      : super(
          retry: null,
          name: r'filteredModulesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Filtered modules by (case-insensitive) query against name and tags (future).
  FilteredModulesProvider call(
    String query,
  ) =>
      FilteredModulesProvider._(argument: query, from: this);

  @override
  String toString() => r'filteredModulesProvider';
}

/// Fetch a single module by id.
@ProviderFor(module)
const moduleProvider = ModuleFamily._();

/// Fetch a single module by id.
final class ModuleProvider
    extends $FunctionalProvider<AsyncValue<Module?>, Module?, FutureOr<Module?>>
    with $FutureModifier<Module?>, $FutureProvider<Module?> {
  /// Fetch a single module by id.
  const ModuleProvider._(
      {required ModuleFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'moduleProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$moduleHash();

  @override
  String toString() {
    return r'moduleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Module?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Module?> create(Ref ref) {
    final argument = this.argument as String;
    return module(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ModuleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moduleHash() => r'44b6ec4187fe26392f1c20585619eb180cb1c67d';

/// Fetch a single module by id.
final class ModuleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Module?>, String> {
  const ModuleFamily._()
      : super(
          retry: null,
          name: r'moduleProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Fetch a single module by id.
  ModuleProvider call(
    String id,
  ) =>
      ModuleProvider._(argument: id, from: this);

  @override
  String toString() => r'moduleProvider';
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
