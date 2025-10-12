// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manuals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Platform _$PlatformFromJson(Map<String, dynamic> json) => _Platform(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  color: json['color'] == null
      ? Colors.blue
      : const ColorConverter().fromJson(json['color'] as String),
  requirements:
      (json['requirements'] as List<dynamic>?)
          ?.map((e) => PlatformRequirement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PlatformToJson(_Platform instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'color': const ColorConverter().toJson(instance.color),
  'requirements': instance.requirements.map((e) => e.toJson()).toList(),
};

_PlatformRequirement _$PlatformRequirementFromJson(Map<String, dynamic> json) =>
    _PlatformRequirement(
      name: json['name'] as String,
      type: $enumDecode(_$PlatformConstraintTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$PlatformRequirementToJson(
  _PlatformRequirement instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': _$PlatformConstraintTypeEnumMap[instance.type]!,
};

const _$PlatformConstraintTypeEnumMap = {
  PlatformConstraintType.version: 'version',
};

PlatformVersionConstraint _$PlatformVersionConstraintFromJson(
  Map<String, dynamic> json,
) => PlatformVersionConstraint(
  versions: (json['versions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$PlatformVersionConstraintToJson(
  PlatformVersionConstraint instance,
) => <String, dynamic>{'versions': instance.versions};

_PlatformTarget _$PlatformTargetFromJson(Map<String, dynamic> json) =>
    _PlatformTarget(
      platform: Platform.fromJson(json['platform'] as Map<String, dynamic>),
      constraints:
          (json['constraints'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              PlatformConstraint.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const {},
    );

Map<String, dynamic> _$PlatformTargetToJson(
  _PlatformTarget instance,
) => <String, dynamic>{
  'platform': instance.platform.toJson(),
  'constraints': instance.constraints.map((k, e) => MapEntry(k, e.toJson())),
};

_ManualModuleReference _$ManualModuleReferenceFromJson(
  Map<String, dynamic> json,
) => _ManualModuleReference(
  moduleId: json['moduleId'] as String,
  name: json['name'] as String,
  version: const SemverJsonConverter().fromJson(json['version']),
  type: const ModuleTypeConverter().fromJson(json['type'] as String),
  dependencies:
      (json['dependencies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  dependents:
      (json['dependents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$ManualModuleReferenceToJson(
  _ManualModuleReference instance,
) => <String, dynamic>{
  'moduleId': instance.moduleId,
  'name': instance.name,
  'version': const SemverJsonConverter().toJson(instance.version),
  'type': const ModuleTypeConverter().toJson(instance.type),
  'dependencies': instance.dependencies,
  'dependents': instance.dependents,
};

_Manual _$ManualFromJson(Map<String, dynamic> json) => _Manual(
  id: json['id'] as String,
  name: json['name'] as String,
  platforms:
      (json['platforms'] as List<dynamic>?)
          ?.map((e) => PlatformTarget.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PlatformTarget>[],
  modules:
      (json['modules'] as List<dynamic>?)
          ?.map(
            (e) => ManualModuleReference.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ManualModuleReference>[],
  autoUpdate: json['autoUpdate'] as bool? ?? true,
);

Map<String, dynamic> _$ManualToJson(_Manual instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'platforms': instance.platforms.map((e) => e.toJson()).toList(),
  'modules': instance.modules.map((e) => e.toJson()).toList(),
  'autoUpdate': instance.autoUpdate,
};

ManualOperationSuccess _$ManualOperationSuccessFromJson(
  Map<String, dynamic> json,
) => ManualOperationSuccess(
  manual: Manual.fromJson(json['manual'] as Map<String, dynamic>),
  $type: json['status'] as String?,
);

Map<String, dynamic> _$ManualOperationSuccessToJson(
  ManualOperationSuccess instance,
) => <String, dynamic>{
  'manual': instance.manual.toJson(),
  'status': instance.$type,
};

ManualOperationFailure _$ManualOperationFailureFromJson(
  Map<String, dynamic> json,
) => ManualOperationFailure(
  reason: json['reason'] as String,
  details:
      (json['details'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  $type: json['status'] as String?,
);

Map<String, dynamic> _$ManualOperationFailureToJson(
  ManualOperationFailure instance,
) => <String, dynamic>{
  'reason': instance.reason,
  'details': instance.details,
  'status': instance.$type,
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(platforms)
const platformsProvider = PlatformsProvider._();

final class PlatformsProvider
    extends $FunctionalProvider<List<Platform>, List<Platform>, List<Platform>>
    with $Provider<List<Platform>> {
  const PlatformsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformsHash();

  @$internal
  @override
  $ProviderElement<List<Platform>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Platform> create(Ref ref) {
    return platforms(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Platform> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Platform>>(value),
    );
  }
}

String _$platformsHash() => r'9fe94ee43929276c3384822f09f47e3eebcb4b93';

/// Provides the list of manuals for the active organization.

@ProviderFor(Manuals)
const manualsProvider = ManualsProvider._();

/// Provides the list of manuals for the active organization.
final class ManualsProvider
    extends $AsyncNotifierProvider<Manuals, List<Manual>> {
  /// Provides the list of manuals for the active organization.
  const ManualsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualsHash();

  @$internal
  @override
  Manuals create() => Manuals();
}

String _$manualsHash() => r'426f7e72c1b4bd5407b8642299c7c2d41d15c564';

/// Provides the list of manuals for the active organization.

abstract class _$Manuals extends $AsyncNotifier<List<Manual>> {
  FutureOr<List<Manual>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Manual>>, List<Manual>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Manual>>, List<Manual>>,
              AsyncValue<List<Manual>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Filtered manuals by (case-insensitive) query against name.

@ProviderFor(filteredManuals)
const filteredManualsProvider = FilteredManualsFamily._();

/// Filtered manuals by (case-insensitive) query against name.

final class FilteredManualsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Manual>>,
          List<Manual>,
          FutureOr<List<Manual>>
        >
    with $FutureModifier<List<Manual>>, $FutureProvider<List<Manual>> {
  /// Filtered manuals by (case-insensitive) query against name.
  const FilteredManualsProvider._({
    required FilteredManualsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredManualsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredManualsHash();

  @override
  String toString() {
    return r'filteredManualsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Manual>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Manual>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredManuals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredManualsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredManualsHash() => r'4e993147d13cc2f76b38470820a3b137732c8000';

/// Filtered manuals by (case-insensitive) query against name.

final class FilteredManualsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Manual>>, String> {
  const FilteredManualsFamily._()
    : super(
        retry: null,
        name: r'filteredManualsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Filtered manuals by (case-insensitive) query against name.

  FilteredManualsProvider call(String query) =>
      FilteredManualsProvider._(argument: query, from: this);

  @override
  String toString() => r'filteredManualsProvider';
}

/// Fetch a manual by id.

@ProviderFor(manual)
const manualProvider = ManualFamily._();

/// Fetch a manual by id.

final class ManualProvider
    extends $FunctionalProvider<AsyncValue<Manual?>, Manual?, FutureOr<Manual?>>
    with $FutureModifier<Manual?>, $FutureProvider<Manual?> {
  /// Fetch a manual by id.
  const ManualProvider._({
    required ManualFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'manualProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualHash();

  @override
  String toString() {
    return r'manualProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Manual?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Manual?> create(Ref ref) {
    final argument = this.argument as String;
    return manual(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ManualProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualHash() => r'50ceb2de6eaa67e03cfa9aaaf9bb452491095ca4';

/// Fetch a manual by id.

final class ManualFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Manual?>, String> {
  const ManualFamily._()
    : super(
        retry: null,
        name: r'manualProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetch a manual by id.

  ManualProvider call(String id) => ManualProvider._(argument: id, from: this);

  @override
  String toString() => r'manualProvider';
}
