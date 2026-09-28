import "package:typewriter_panel/typewriter_panel.dart";

RealmEditorCatalogSnapshot authoringSearchStoryCatalog(
  RealmEditorCatalogSnapshot base,
) {
  final snapshot = base;
  return snapshot.copyWith(
    elements: {
      for (final entry in snapshot.elements.entries)
        entry.key: entry.value.copyWith(
          definition: entry.value.definition.copyWith(
            icon: const IconValue.iconify("fa6-solid:cube"),
          ),
        ),
    },
    pageCatalog: snapshot.pageCatalog.copyWith(
      definitions: {
        for (final entry in snapshot.pageCatalog.definitions.entries)
          entry.key: entry.value.copyWith(
            icon: const IconValue.iconify("fa6-solid:diagram-project"),
          ),
      },
    ),
  );
}
