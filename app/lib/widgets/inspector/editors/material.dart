import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fuzzy/fuzzy.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/materials.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/input_field.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "material.g.dart";

typedef CombinedMaterial = MapEntry<String, MinecraftMaterial>;

@riverpod
List<MaterialProperty> materialProperties(
  Ref ref,
  String meta,
) {
  return meta
      .split(";")
      .map(
        (property) => MaterialProperty.values.firstWhere(
          (element) => element.name.toLowerCase() == property,
          orElse: () => throw Exception("Unknown material property: $property"),
        ),
      )
      .toList();
}

@riverpod
Map<String, MinecraftMaterial> availableMaterialsMap(Ref ref) {
  final version = ref.watch(serverVersionProvider);
  return availableMaterials(version);
}

@riverpod
bool isMaterialAvailable(Ref ref, String material) {
  final available = ref.watch(availableMaterialsMapProvider);
  return available.containsKey(material);
}

@riverpod
Fuzzy<CombinedMaterial> _fuzzyMaterials(Ref ref) {
  final available = ref.watch(availableMaterialsMapProvider);
  return Fuzzy(
    available.entries.toList(),
    options: FuzzyOptions(
      threshold: 0.2,
      keys: [
        WeightedKey(
          name: "name",
          getter: (entry) => entry.value.name,
          weight: 0.7,
        ),
        WeightedKey(
          name: "id",
          getter: (entry) => entry.key,
          weight: 0.3,
        ),
        WeightedKey(
          name: "properties",
          getter: (entry) =>
              entry.value.properties.map((p) => p.name).join(" "),
          weight: 0.2,
        ),
      ],
    ),
  );
}

class MaterialsFetcher extends SearchFetcher {
  const MaterialsFetcher({
    this.onSelect,
    this.disabled = false,
  });

  final bool? Function(CombinedMaterial)? onSelect;

  @override
  final bool disabled;

  @override
  String get title => "Materials";

  @override
  List<SearchElement> fetch(PassingRef ref, String query) {
    final fuzzy = ref.read(_fuzzyMaterialsProvider);

    final results = fuzzy.search(query);

    return results.map((result) {
      final material = result.item;
      return MaterialSearchElement(material, onSelect: onSelect);
    }).toList();
  }

  @override
  SearchFetcher copyWith({
    bool? disabled,
  }) {
    return MaterialsFetcher(
      onSelect: onSelect,
      disabled: disabled ?? this.disabled,
    );
  }
}

class MaterialSearchElement extends SearchElement {
  const MaterialSearchElement(this.material, {this.onSelect});

  final CombinedMaterial material;
  final bool? Function(CombinedMaterial)? onSelect;

  @override
  String get title => material.value.name;

  @override
  Color color(BuildContext context) {
    final properties = material.value.properties;
    final isDark = context.isDark;

    if (properties.contains(MaterialProperty.item)) {
      return isDark ? Colors.black38 : Colors.black12;
    }
    if (properties.contains(MaterialProperty.block)) {
      return isDark ? Colors.black54 : Colors.black26;
    }

    return Colors.grey;
  }

  @override
  Widget icon(BuildContext context) => Image.asset(material.value.icon);

  @override
  Widget suffixIcon(BuildContext context) =>
      const Iconify(TWIcons.externalLink);

  @override
  String description(BuildContext context) => material.key;

  @override
  List<SearchAction> actions(PassingRef ref) {
    return [
      const SearchAction(
        "Select",
        TWIcons.check,
        SingleActivator(LogicalKeyboardKey.enter),
      ),
    ];
  }

  @override
  Future<bool> activate(BuildContext context, PassingRef ref) async {
    return onSelect?.call(material) ?? true;
  }
}

class MaterialPropertyFilter extends SearchFilter {
  const MaterialPropertyFilter(this.property, {this.canRemove = false});

  final MaterialProperty property;

  @override
  final bool canRemove;

  @override
  String get title => property.name;

  @override
  Color get color => property.color;
  @override
  String get icon => property.icon;
}

extension _SearchBuilderX on SearchBuilder {
  void fetchMaterials({
    bool? Function(CombinedMaterial)? onSelect,
    bool disabled = false,
  }) {
    fetch(MaterialsFetcher(onSelect: onSelect, disabled: disabled));
  }

  void properties(List<MaterialProperty> properties) {
    for (final property in properties) {
      filter(MaterialPropertyFilter(property));
    }
  }
}

class MaterialEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "material";
  @override
  Widget build(String path, DataBlueprint dataBlueprint) => MaterialEditor(
        path: path,
        customBlueprint: dataBlueprint as CustomBlueprint,
      );
}

class MaterialEditor extends HookConsumerWidget {
  const MaterialEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  }) : super();

  final String path;
  final CustomBlueprint customBlueprint;

  bool? _update(WidgetRef ref, String value) {
    ref
        .read(inspectingEntryDefinitionProvider)
        ?.updateField(ref.passing, path, value.toUpperCase());
    return null;
  }

  void _select(WidgetRef ref, List<MaterialProperty> properties) {
    ref.read(searchProvider.notifier).asBuilder()
      ..properties(properties)
      ..fetchMaterials(onSelect: (material) => _update(ref, material.key))
      ..open();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value =
        ref.watch(fieldValueProvider(path, customBlueprint.defaultValue()));
    final propertiesModifier =
        customBlueprint.getModifier("material_properties");
    final properties = propertiesModifier != null
        ? ref.watch(materialPropertiesProvider(propertiesModifier.data))
        : <MaterialProperty>[];

    final currentValue = value.isEmpty ? "air" : value.toLowerCase();
    final currentMaterial = materials[currentValue];
    final hasMaterial = currentMaterial != null;
    final isAvailable = ref.watch(isMaterialAvailableProvider(currentValue));

    return InputField(
      child: InkWell(
        onTap: () => _select(ref, properties),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              if (hasMaterial)
                Expanded(
                  child: Column(
                    children: [
                      MaterialItem(
                        id: currentValue,
                        material: currentMaterial,
                        isAvailable: isAvailable,
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Text(
                    "Select a material",
                    style: Theme.of(context).inputDecorationTheme.hintStyle,
                  ),
                ),
              const SizedBox(width: 12),
              Iconify(
                TWIcons.caretDown,
                size: 16,
                color: Theme.of(context).inputDecorationTheme.hintStyle?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaterialItem extends ConsumerWidget {
  const MaterialItem({
    required this.id,
    required this.material,
    this.isAvailable = true,
    super.key,
  });

  final String id;
  final MinecraftMaterial material;
  final bool isAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.asset(material.icon),
        ),
      ),
      title: AutoSizeText(
        material.name,
        maxLines: 1,
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            "minecraft:$id",
            maxLines: 1,
          ),
          if (!isAvailable)
            Text(
              "Unavailable on ${ref.watch(serverVersionProvider).name} servers",
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.orange),
            ),
        ],
      ),
    );
  }
}
