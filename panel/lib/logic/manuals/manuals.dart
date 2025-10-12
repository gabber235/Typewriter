import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart" hide Title;
import "package:freezed_annotation/freezed_annotation.dart";
import "package:pub_semver/pub_semver.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/models/module.pbenum.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/logic/modules/semver_json_converter.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/color_converter.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";

part "manuals.freezed.dart";
part "manuals.g.dart";

const paperPlatform = Platform(
  id: "papermc",
  displayName: "PaperMC",
  color: Colors.blue,
  requirements: [
    PlatformRequirement(
      name: "minecraft_version",
      type: PlatformConstraintType.version,
    ),
  ],
);

@riverpod
List<Platform> platforms(Ref ref) => const [paperPlatform];

@freezed
abstract class Platform with _$Platform {
  const factory Platform({
    required String id,
    required String displayName,
    @ColorConverter() @Default(Colors.blue) Color color,
    @Default([]) List<PlatformRequirement> requirements,
  }) = _Platform;

  factory Platform.fromJson(Map<String, dynamic> json) =>
      _$PlatformFromJson(json);
}

PlatformConstraint _platformVersion() =>
    PlatformConstraint.version(versions: []);

@JsonEnum(fieldRename: FieldRename.snake)
enum PlatformConstraintType {
  version(_platformVersion);

  const PlatformConstraintType(this.constraintBuilder);

  final PlatformConstraint Function() constraintBuilder;
}

@freezed
abstract class PlatformRequirement with _$PlatformRequirement {
  const factory PlatformRequirement({
    required String name,
    required PlatformConstraintType type,
  }) = _PlatformRequirement;

  factory PlatformRequirement.fromJson(Map<String, dynamic> json) =>
      _$PlatformRequirementFromJson(json);
}

/// A platform constraint. Future variants can be added without breaking existing APIs.
@Freezed(unionKey: "type", unionValueCase: FreezedUnionCase.snake)
sealed class PlatformConstraint with _$PlatformConstraint {
  const PlatformConstraint._();

  /// Versions constraint: a list of explicit Versions. An item matches if it is contained in the list.
  const factory PlatformConstraint.version({required List<String> versions}) =
      PlatformVersionConstraint;

  factory PlatformConstraint.fromJson(Map<String, dynamic> json) =>
      _$PlatformConstraintFromJson(json);

  String get display => switch (this) {
    PlatformVersionConstraint(versions: final vs) =>
      vs.isEmpty ? "any" : vs.join(", "),
  };
}

/// A target platform and its constraints for the manual.
@freezed
abstract class PlatformTarget with _$PlatformTarget {
  const factory PlatformTarget({
    required Platform platform,
    @Default({}) Map<String, PlatformConstraint> constraints,
  }) = _PlatformTarget;

  factory PlatformTarget.fromJson(Map<String, dynamic> json) =>
      _$PlatformTargetFromJson(json);

  static PlatformTarget fromPlatform(Platform platform) {
    return PlatformTarget(
      platform: platform,
      constraints: {
        for (final requirement in platform.requirements)
          requirement.name: requirement.type.constraintBuilder(),
      },
    );
  }
}

/// Reference to a module pinned in a manual.
@freezed
abstract class ManualModuleReference with _$ManualModuleReference {
  const factory ManualModuleReference({
    required String moduleId,
    required String name,
    @SemverJsonConverter() required Version version,
    @ModuleTypeConverter() required ModuleType type,
    @Default(<String>[]) List<String> dependencies,
    @Default(<String>[]) List<String> dependents,
  }) = _ManualModuleReference;

  factory ManualModuleReference.fromJson(Map<String, dynamic> json) =>
      _$ManualModuleReferenceFromJson(json);
}

/// Manual: defines a platform target set and a set of modules for a book or a group of books.
@freezed
abstract class Manual with _$Manual {
  const factory Manual({
    required String id,
    required String name,
    @Default(<PlatformTarget>[]) List<PlatformTarget> platforms,
    @Default(<ManualModuleReference>[]) List<ManualModuleReference> modules,
    @Default(true) bool autoUpdate,
  }) = _Manual;

  factory Manual.fromJson(Map<String, dynamic> json) => _$ManualFromJson(json);
}

/// Operation result for backend-validated mutations.
@Freezed(unionKey: "status", unionValueCase: FreezedUnionCase.snake)
sealed class ManualOperationResult with _$ManualOperationResult {
  const factory ManualOperationResult.success({required Manual manual}) =
      ManualOperationSuccess;
  const factory ManualOperationResult.failure({
    required String reason,
    @Default(<String>[]) List<String> details,
  }) = ManualOperationFailure;

  factory ManualOperationResult.fromJson(Map<String, dynamic> json) =>
      _$ManualOperationResultFromJson(json);
}

/// Provides the list of manuals for the active organization.
@riverpod
class Manuals extends _$Manuals {
  @override
  FutureOr<List<Manual>> build() async {
    // TODO: Load manuals from backend.
    return <Manual>[];
  }

  Future<void> create() async {
    // TODO: Implement create
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> upsertManual(Manual manual) async {
    state.ensureReady();

    // TODO: Implement optimistic update

    // TODO: Call backend to upsert manual.
    throw UnimplementedError();
  }

  Future<ManualOperationResult> changePlatformTargets({
    required String manualId,
    required List<PlatformTarget> proposed,
  }) async {
    state.ensureReady();

    // TODO: Implement optimistic update

    // TODO: Call backend to validate and apply platform constraints.
    throw UnimplementedError();
  }

  Future<ManualOperationResult> changeModules({
    required String manualId,
    required List<ManualModuleReference> proposed,
  }) async {
    state.ensureReady();

    // TODO: Implement optimistic update

    // TODO: Call backend to validate and resolve dependencies for module set.
    throw UnimplementedError();
  }

  Future<void> deleteManual(String id) async {
    state.ensureReady();

    // TODO: Do optimistic update

    // TODO: Implement deleteManual
    await Future.delayed(const Duration(seconds: 1));
  }
}

/// Filtered manuals by (case-insensitive) query against name.
@riverpod
Future<List<Manual>> filteredManuals(Ref ref, String query) async {
  final manuals = await ref.watch(manualsProvider.future);
  if (query.isEmpty) return manuals;
  final q = query.toLowerCase();
  return manuals.where((m) => m.name.toLowerCase().contains(q)).toList();
}

/// Fetch a manual by id.
@riverpod
Future<Manual?> manual(Ref ref, String id) async {
  final manuals = await ref.watch(manualsProvider.future);
  return manuals.firstWhereOrNull((m) => m.id == id);
}

/// Identifier for a selectable Manual.
class ManualSelector extends SelectableIdentifier {
  ManualSelector(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final asyncManual = ref.watch(manualProvider(id));
    return asyncManual.whenData((manual) {
      if (manual == null) {
        throw SelectableNotFoundException(this);
      }
      return ManualSelection(ref: ref, id: this, manual: manual);
    });
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ManualSelector && other.id == id;

  @override
  String toString() => "ManualSelector(id: $id)";
}

/// Selectable representation of a manual for the inspector.
class ManualSelection extends Selectable<ManualSelector> {
  ManualSelection({required this.ref, required this.id, required this.manual})
    : _data = DynamicData(manual.toJson());

  @override
  final ManualSelector id;

  final Manual manual;
  final Ref ref;
  final DynamicData _data;

  @override
  String get name => manual.name;

  @override
  ObjectBlueprint get objectBlueprint {
    return ObjectBlueprint(
      fields: {
        "name": DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
        "platforms": DataBlueprint.list(
          type: DataBlueprint.manualPlatformTarget(
            modifiers: [Modifier.expanded()],
          ),
          modifiers: [Modifier.readOnly(recursive: true), Modifier.expanded()],
        ),
        "modules": DataBlueprint.list(
          type: DataBlueprint.manualModuleReference(
            modifiers: [Modifier.expanded()],
          ),
          modifiers: [Modifier.readOnly(recursive: true), Modifier.expanded()],
        ),
        "autoUpdate": DataBlueprint.boolean(),
      },
    );
  }

  @override
  List<SelectableOperation> get operations => [];

  @override
  Widget? header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Title(title: manual.name, color: Colors.blue),
      const SizedBox(height: 8),
      Identifier(id: manual.id),
    ],
  );

  @override
  dynamic fieldValue(String path) => _data.get(path);

  @override
  void setFieldValue(String path, dynamic value) {
    final newData = _data.copyWith(path, value);
    final updated = Manual.fromJson(newData.toJson());
    ref.read(manualsProvider.notifier).upsertManual(updated);
  }

  @override
  int get hashCode => Object.hash(id, manual);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualSelection && other.id == id && other.manual == manual;

  @override
  String toString() => "ManualSelection(id: $id, manual: $manual)";
}

class SemverListJsonConverter
    implements JsonConverter<List<Version>, List<dynamic>> {
  const SemverListJsonConverter();

  @override
  List<Version> fromJson(List<dynamic> json) {
    const single = SemverJsonConverter();
    return json.map(single.fromJson).toList();
  }

  @override
  List<dynamic> toJson(List<Version> object) {
    return object.map((v) => v.canonicalizedVersion).toList();
  }
}
