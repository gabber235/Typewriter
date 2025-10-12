import "package:collection/collection.dart";
import "package:flutter/material.dart" hide Title;
import "package:json_annotation/json_annotation.dart";
import "package:pub_semver/pub_semver.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/api/module.pb.dart";
import "package:typewriter_panel/generated/models/module.pb.dart";
import "package:typewriter_panel/logic/modules/module_type_extensions.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";
import "package:typewriter_panel/widgets/generic/components/type_link.dart";

part "modules.g.dart";

/// Provides the list of available modules.
@riverpod
class Modules extends _$Modules {
  @override
  FutureOr<List<Module>> build() async {
    final request = ListModulesRequest();
    final response = await ref
        .watch(natsProvider)
        .requestProto("modules.list", request, ListModulesResponse.new);

    return response.modules;
  }

  Future<void> updateModule(Module module) async {
    state.ensureReady();

    final currentState = state.value ?? [];
    final optimisticState = currentState
        .map((m) => m.id == module.id ? module : m)
        .toList();
    state = AsyncData(optimisticState);

    try {
      final request = UpdateModuleRequest()..module = module;
      final response = await ref
          .watch(natsProvider)
          .requestProto("modules.update", request, UpdateModuleResponse.new);

      if (response.hasError()) {
        state = AsyncData(currentState);
        throw Exception("Failed to update module: ${response.error.message}");
      }

      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(currentState);
      rethrow;
    }
  }

  Future<void> changeVersionState(
    List<String> moduleIds,
    Version version,
    ModuleVersionState newState,
  ) async {
    state.ensureReady();

    final currentState = state.value ?? [];
    final optimisticState = currentState.map((module) {
      if (!moduleIds.contains(module.id)) {
        return module;
      }
      final clonedModule = module.deepCopy();

      final updatedVersions = clonedModule.versions.map((v) {
        if (v.version != version.canonicalizedVersion) {
          return v;
        }
        final clonedVersion = v.deepCopy()..state = newState;
        return clonedVersion;
      }).toList();

      clonedModule.versions.clear();
      clonedModule.versions.addAll(updatedVersions);

      return clonedModule;
    }).toList();
    state = AsyncData(optimisticState);

    try {
      final request = ChangeVersionStateRequest()
        ..moduleIds.addAll(moduleIds)
        ..version = version.canonicalizedVersion
        ..state = newState;

      final response = await ref
          .watch(natsProvider)
          .requestProto(
            "modules.changeVersionState",
            request,
            ChangeVersionStateResponse.new,
          );

      if (response.hasError()) {
        state = AsyncData(currentState);
        throw Exception(
          "Failed to change version state: ${response.error.message}",
        );
      }

      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(currentState);
      rethrow;
    }
  }
}

/// Filtered modules by (case-insensitive) query against name and tags (future).
@riverpod
Future<List<Module>> filteredModules(Ref ref, String query) async {
  final modules = await ref.watch(modulesProvider.future);
  if (query.isEmpty) return modules;
  final q = query.toLowerCase();
  return modules.where((m) {
    if (m.name.toLowerCase().contains(q)) return true;
    // TODO: Include dependency / tag matching once available.
    return false;
  }).toList();
}

/// Fetch a single module by id.
@riverpod
Future<Module?> module(Ref ref, String id) async {
  final modules = await ref.watch(modulesProvider.future);
  return modules.firstWhereOrNull((m) => m.id == id);
}

// ignore: prefer_mixin

class ModuleTypeConverter extends JsonConverter<ModuleType, String> {
  const ModuleTypeConverter();

  @override
  ModuleType fromJson(String json) {
    switch (json) {
      case "MODULE_TYPE_ENGINE":
        return ModuleType.MODULE_TYPE_ENGINE;
      case "MODULE_TYPE_EXTENSION":
        return ModuleType.MODULE_TYPE_EXTENSION;
      default:
        throw FormatException("Unknown ModuleType: $json");
    }
  }

  @override
  String toJson(ModuleType object) {
    switch (object) {
      case ModuleType.MODULE_TYPE_ENGINE:
        return "MODULE_TYPE_ENGINE";
      case ModuleType.MODULE_TYPE_EXTENSION:
        return "MODULE_TYPE_EXTENSION";
      default:
        throw ArgumentError("Unknown ModuleType: $object");
    }
  }
}

/// Identifier for a selectable Module.
class ModuleSelector extends SelectableIdentifier {
  ModuleSelector(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final asyncModule = ref.watch(moduleProvider(id));
    return asyncModule.whenData((value) {
      if (value == null) {
        throw SelectableNotFoundException(this);
      }
      return ModuleSelection(ref: ref, id: this, module: value);
    });
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ModuleSelector && other.id == id;

  @override
  String toString() => "ModuleSelector(id: $id)";
}

/// Selectable representation of a module for the inspector.
class ModuleSelection extends Selectable<ModuleSelector> {
  ModuleSelection({required this.ref, required this.id, required this.module})
    : _data = DynamicData(module.writeToJsonMap());

  @override
  final ModuleSelector id;

  final Module module;
  final Ref ref;
  final DynamicData _data;

  @override
  String get name => module.name;

  @override
  ObjectBlueprint get objectBlueprint {
    return ObjectBlueprint(
      fields: {
        "name": DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
        // TODO: dependencies editor (multi-select of other modules).
        // "dependencies": DataBlueprint.list(type: DataBlueprint.string()),
        "versions": DataBlueprint.list(
          type: DataBlueprint.moduleVersion(),
          modifiers: [Modifier.readOnly(recursive: false), Modifier.expanded()],
        ),
      },
    );
  }

  @override
  List<SelectableOperation> get operations => [];

  @override
  Widget? header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Title(
        title: module.name.formatted,
        color: module.type.lightColor.withValues(alpha: 0.9),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          direction: Axis.horizontal,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            TypeLink(
              text: module.type.displayName,
              lightColor: module.type.lightColor,
              darkColor: module.type.darkColor,
              url: module.type.docsUrl,
            ),
            Identifier(id: module.id),
          ],
        ),
      ),
    ],
  );

  @override
  dynamic fieldValue(String path) => _data.get(path);

  @override
  void setFieldValue(String path, dynamic value) {
    final newData = _data.copyWith(path, value);
    final newModule = Module()..mergeFromJsonMap(newData.toJson());
    ref.read(modulesProvider.notifier).updateModule(newModule);
  }

  @override
  int get hashCode => Object.hash(id, module);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleSelection && other.id == id && other.module == module;

  @override
  String toString() => "ModuleSelection(id: $id, module: $module)";
}
