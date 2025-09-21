// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Module _$ModuleFromJson(Map<String, dynamic> json) => _Module(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$ModuleTypeEnumMap, json['type']),
  shortDescription: json['shortDescription'] as String? ?? "",
  versions:
      (json['versions'] as List<dynamic>?)
          ?.map((e) => ModuleVersion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ModuleVersion>[],
);

Map<String, dynamic> _$ModuleToJson(_Module instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$ModuleTypeEnumMap[instance.type]!,
  'shortDescription': instance.shortDescription,
  'versions': instance.versions.map((e) => e.toJson()).toList(),
};

const _$ModuleTypeEnumMap = {
  ModuleType.engine: 'engine',
  ModuleType.extension: 'extension',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the list of available modules.

@ProviderFor(Modules)
const modulesProvider = ModulesProvider._();

/// Provides the list of available modules.
final class ModulesProvider
    extends $AsyncNotifierProvider<Modules, List<Module>> {
  /// Provides the list of available modules.
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

String _$modulesHash() => r'be8391aa51fe7287f7316612a3cbbce03b019f11';

/// Provides the list of available modules.

abstract class _$Modules extends $AsyncNotifier<List<Module>> {
  FutureOr<List<Module>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Module>>, List<Module>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Module>>, List<Module>>,
              AsyncValue<List<Module>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Filtered modules by (case-insensitive) query against name and tags (future).

@ProviderFor(filteredModules)
const filteredModulesProvider = FilteredModulesFamily._();

/// Filtered modules by (case-insensitive) query against name and tags (future).

final class FilteredModulesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Module>>,
          List<Module>,
          FutureOr<List<Module>>
        >
    with $FutureModifier<List<Module>>, $FutureProvider<List<Module>> {
  /// Filtered modules by (case-insensitive) query against name and tags (future).
  const FilteredModulesProvider._({
    required FilteredModulesFamily super.from,
    required String super.argument,
  }) : super(
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
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Module>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredModules(ref, argument);
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

  FilteredModulesProvider call(String query) =>
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
  const ModuleProvider._({
    required ModuleFamily super.from,
    required String super.argument,
  }) : super(
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
    return module(ref, argument);
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

  ModuleProvider call(String id) => ModuleProvider._(argument: id, from: this);

  @override
  String toString() => r'moduleProvider';
}
