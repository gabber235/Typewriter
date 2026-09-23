import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class RelationAddMenu extends ConsumerWidget {
  const RelationAddMenu({
    required this.host,
    required this.rootType,
    super.key,
  });

  final skir.ResourceId host;
  final ResolvedTypeRef rootType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(realmEditorCatalogProvider).value?.snapshot;
    if (catalog == null) return const SizedBox.shrink();
    final fields = <RealmRelationField>[
      for (final relation in catalog.relations.values)
        for (final endpoint in [
          relation.sourceEndpoint,
          relation.targetEndpoint,
        ])
          if (endpoint != null &&
              endpoint.cardinality == RealmRelationCardinality.many)
            if (catalog.relationField(rootType, endpoint.path)
                case final field?)
              if (field.relation.id == relation.id) field,
    ];
    if (fields.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<RealmRelationField>(
      tooltip: "Add related resource",
      icon: const Icon(Icons.add),
      itemBuilder: (context) => [
        for (final field in fields)
          PopupMenuItem(
            value: field,
            child: Text(_fieldLabel(field.endpoint.path)),
          ),
      ],
      onSelected: (field) => showAddRelationSearch(
        context,
        host: host,
        fieldPath: field.endpoint.path,
      ),
    );
  }
}

String _fieldLabel(DataPath path) {
  final name = switch (path.segments.lastOrNull) {
    FieldPathSegment(:final name) => name,
    _ => path.toString(),
  };
  final words = name
      .replaceAllMapped(
        RegExp("([a-z0-9])([A-Z])"),
        (match) => "${match[1]} ${match[2]}",
      )
      .replaceAll("_", " ");
  return words.isEmpty ? words : words[0].toUpperCase() + words.substring(1);
}
