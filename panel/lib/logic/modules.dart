import "package:collection/collection.dart";
import "package:flutter/material.dart" hide Title;
import "package:freezed_annotation/freezed_annotation.dart";
import "package:mocktail/mocktail.dart";
import "package:pub_semver/pub_semver.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/module_version/module_version.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";
import "package:typewriter_panel/widgets/generic/components/type_link.dart";

part "modules.freezed.dart";
part "modules.g.dart";

/// Provides the list of available modules (engines + extensions).
@riverpod
class Modules extends _$Modules {
  @override
  FutureOr<List<Module>> build() async {
    // TODO: Load modules from backend.
    return [];
  }

  Future<void> updateModule(Module module) async {
    // TODO: Persist module updates.
    final current = state.when(
      data: (d) => d,
      error: (_, __) => <Module>[],
      loading: () => <Module>[],
    );
    final updated = [
      for (final m in current)
        if (m.id == module.id) module else m,
      if (!current.any((m) => m.id == module.id)) module,
    ];
    state = AsyncData(updated);
  }

  Future<void> changeVersionState(
    List<String> moduleIds,
    Version version,
    ModuleVersionState state,
  ) {
    // TODO: Publish module to backend.
    return Future.value();
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
class ModulesMock extends _$Modules with Mock implements Modules {}

@freezed
abstract class Module with _$Module {
  const factory Module({
    required String id,
    required String name,
    required ModuleKind kind,
    @Default("") String shortDescription,
    // TODO: dependencies: list of module ids this module depends on.
    // @Default(<String>[]) List<String> dependencies,
    @Default(<ModuleVersion>[]) List<ModuleVersion> versions,
  }) = _Module;

  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum ModuleKind {
  engine(
    "Engine",
    Colors.blue,
    "https://docs.typewritermc.com/develop",
  ),
  extension(
    "Extension",
    Colors.green,
    "https://docs.typewritermc.com/develop/extensions",
  ),
  ;

  const ModuleKind(
    this.displayName,
    this.lightColor,
    this.docsUrl, [
    Color? darkColor,
  ]) : darkColor = darkColor ?? lightColor;

  final String displayName;
  final Color lightColor;
  final Color darkColor;
  final String docsUrl;
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
      return ModuleSelection(
        ref: ref,
        id: this,
        module: value,
      );
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
  ModuleSelection({
    required this.ref,
    required this.id,
    required this.module,
  }) : _data = DynamicData(module.toJson());

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
            color: module.kind.lightColor.withValues(alpha: 0.9),
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
                  text: module.kind.displayName,
                  lightColor: module.kind.lightColor,
                  darkColor: module.kind.darkColor,
                  url: module.kind.docsUrl,
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
    final newModule = Module.fromJson(newData.toJson());
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
