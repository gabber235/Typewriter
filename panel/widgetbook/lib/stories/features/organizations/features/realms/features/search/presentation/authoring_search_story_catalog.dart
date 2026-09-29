import "package:typewriter_panel/typewriter_panel.dart";

RealmEditorCatalogSnapshot authoringSearchStoryCatalog(
  RealmEditorCatalogSnapshot base,
) {
  final snapshot = base;
  return snapshot.copyWith(
    types: {
      for (final entry in snapshot.types.entries)
        entry.key: entry.value.copyWith(
          icon: entry.value.editor == null
              ? const IconValue.iconify("fa6-solid:cube")
              : const IconValue.iconify("fa6-solid:diagram-project"),
        ),
    },
  );
}
