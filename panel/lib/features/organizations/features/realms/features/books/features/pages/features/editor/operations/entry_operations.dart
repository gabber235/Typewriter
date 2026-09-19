import "dart:async";

import "package:flutter/material.dart" hide Page;
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const entrySelectionOperations = <SelectionOperation>[
  EntryLinkWithOperation(),
  EntryLinkWithDuplicateOperation(),
  EntryDuplicateOperation(),
  EntryMoveToPageOperation(),
  EntryReplaceWithOperation(),
];

/// Links selected entries through one shared compatible reference field.
///
/// The target picker accepts an existing entry or creates a compatible entry
/// on the source page before applying the links.
class EntryLinkWithOperation extends ActivatorShortcutOperation {
  const EntryLinkWithOperation();

  @override
  String get name => "Link with...";

  @override
  String get description => "Create a connection to another entry";

  Color get color => Colors.blue;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyL),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allAre<EntrySelection>()) return false;
    final entries = selection.whereType<EntrySelection>().toList();
    final hasLinkablePaths = _linkablePaths(entries).isNotEmpty;
    return hasLinkablePaths;
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );
    final target = await _selectLinkTarget(ref, entries);
    if (target == null || !ref.context.mounted) return;
    await _linkEntries(ref, entries, target);
  }

  List<TypeReferenceLocation> _linkablePaths(List<EntrySelection> entries) {
    if (entries.isEmpty) return [];
    return entries
        .map(
          (entry) =>
              entry.referenceLocations().valueOrNull?.toSet() ??
              <TypeReferenceLocation>{},
        )
        .reduce((left, right) => left.intersection(right))
        .toList(growable: false);
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.link),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(Fa6Solid.link),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Duplicates selected entries and links every original to its own copy.
///
/// Copies, internal reference rewrites, and original links use one previewed
/// authoring batch.
class EntryLinkWithDuplicateOperation extends ActivatorShortcutOperation {
  const EntryLinkWithDuplicateOperation();

  @override
  String get name => "Link with Duplicate";

  @override
  String get description => "Create a linked copy of every selected entry";

  Color get color => Colors.orange;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyL, shift: true),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allAre<EntrySelection>()) return false;
    final entries = selection.whereType<EntrySelection>().toList();
    final hasLinkablePaths = _linkableDuplicatePaths(entries).isNotEmpty;
    return hasLinkablePaths;
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );
    final path = await _selectDuplicateLinkPath(ref, entries);
    if (path == null || !ref.context.mounted) return;
    final cached = _cachedEntries(ref, entries);
    final pageIds = cached.map((entry) => entry.pageId).toSet();
    if (pageIds.length != 1) {
      throw ApiException.badRequest("Linked entries must belong to one page");
    }
    final duplicated = await ref.withReadyPageElements(
      pageIds.single,
      (elements) => elements.duplicateAndLink(
        entries.map((entry) => entry.id.id).toList(growable: false),
        path,
      ),
    );
    ref
        .read(selectionProvider.notifier)
        .selectAll(duplicated.map(EntryIdentifier.new).toList(growable: false));
  }

  List<TypeReferenceLocation> _linkableDuplicatePaths(
    List<EntrySelection> entries,
  ) {
    if (entries.isEmpty) return [];
    return entries
        .map(
          (entry) =>
              entry.referenceLocations().valueOrNull?.toSet() ??
              <TypeReferenceLocation>{},
        )
        .reduce((left, right) => left.intersection(right))
        .toList(growable: false);
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.copy),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(Fa6Solid.copy),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Duplicates selected entries from one page and selects the created entries.
///
/// The operation rejects mixed page selections because duplication is submitted
/// through one page coordinator. Backend conflicts remain visible to the caller.
class EntryDuplicateOperation extends ActivatorShortcutOperation {
  const EntryDuplicateOperation();

  @override
  String get name => "Duplicate";

  @override
  String get description => "Create a copy of this entry";

  Color get color => Colors.green;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyD),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );
    final cached = _cachedEntries(ref, entries);
    final pageIds = {for (final entry in cached) entry.pageId};
    if (pageIds.length != 1) {
      throw ApiException.badRequest(
        "Entries from different pages cannot be duplicated together",
      );
    }

    final duplicated = await ref.withReadyPageElements(pageIds.single, (
      elements,
    ) {
      _requireEntriesOnPage(ref, entries, pageIds.single);
      return elements.duplicateAll(
        entries.map((entry) => entry.id.id).toList(),
      );
    });
    ref
        .read(selectionProvider.notifier)
        .selectAll(duplicated.map(EntryIdentifier.new).toList());
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.clone),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(Fa6Solid.clone),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Moves selected entries to a compatible page and clears their old selection.
///
/// Entries must share one source page and placement kind. The target list is
/// filtered by the catalog editor that can render that placement kind.
class EntryMoveToPageOperation extends ActivatorShortcutOperation {
  const EntryMoveToPageOperation();

  @override
  String get name => "Move to...";

  @override
  String get description => "Move this entry to another page";

  Color get color => Colors.blueAccent;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyM),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );

    final cached = _cachedEntries(ref, entries);
    final sourcePageIds = {for (final entry in cached) entry.pageId};

    if (sourcePageIds.length != 1) {
      throw ApiException.badRequest(
        "Entries from different pages cannot be moved together",
      );
    }

    final placementKinds = {
      for (final entry in cached) entry.definition.placement.kind,
    };
    if (placementKinds.length != 1) {
      throw ApiException.badRequest(
        "Graph and timeline entries cannot be moved together",
      );
    }

    final books = await ref.read(canonicalBooksProvider.future);
    final placementCompatiblePages =
        (await Future.wait([
              for (final book in books)
                ref.read(canonicalBookPagesProvider(book.bookId).future),
            ]))
            .expand((values) => values)
            .where((page) {
              if (page.pageId.id == sourcePageIds.single) return false;
              final editor = ref
                  .read(realmEditorCatalogProvider)
                  .value
                  ?.snapshot
                  ?.pageCatalog
                  .definitions[page.kind]
                  ?.editor;
              return switch (placementKinds.single) {
                EntryPlacementKind.graph => editor is RealmGraphPageEditor,
                EntryPlacementKind.timelineEntry =>
                  editor is RealmTimelinePageEditor,
              };
            })
            .toList(growable: false);
    final rootTypes = {
      for (final entry in cached) entry.definition.elementDefinition.rootType,
    };
    final pages = (await Future.wait([
      for (final page in placementCompatiblePages)
        ref.read(pageElementTypesProvider(page.kind).future).then((state) {
          return switch (state) {
            PageElementTypesReady(:final types)
                when rootTypes.every(types.contains) =>
              page,
            _ => null,
          };
        }),
    ])).nonNulls.toList(growable: false);

    if (!ref.context.mounted) return;
    final target = await _selectTargetPage(ref, pages);
    if (target == null) return;
    await ref.withReadyPageElements(sourcePageIds.single, (elements) {
      _requireEntriesOnPage(ref, entries, sourcePageIds.single);
      return elements.moveEntriesToPage(
        entries.map((entry) => entry.id.id).toList(growable: false),
        target.pageId.id,
      );
    });
    ref
        .read(selectionProvider.notifier)
        .unselectAll(entries.map((entry) => entry.id).toList(growable: false));
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(HeroiconsSolid.arrow_right),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(HeroiconsSolid.arrow_right),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

List<CachedPageEntry> _cachedEntries(
  WidgetRef ref,
  List<EntrySelection> entries,
) => _cachedEntryIdentifiers(ref, entries.map((entry) => entry.id));

List<CachedPageEntry> _cachedEntryIdentifiers(
  WidgetRef ref,
  Iterable<EntryIdentifier> entries,
) {
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  if (organizationId == null) throw ApiException.noOrganization();
  if (realmId == null) throw ApiException.badRequest("No realm selected");
  final index = ref
      .read(realmEntryIndexProvider(organizationId, realmId))
      .requireValue;
  return [
    for (final entry in entries)
      index[entry.id] ?? (throw ApiException.notFound("Entry")),
  ];
}

Future<EntryIdentifier?> _selectLinkTarget(
  WidgetRef ref,
  List<EntrySelection> entries,
) {
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  if (organizationId == null) throw ApiException.noOrganization();
  if (realmId == null) throw ApiException.badRequest("No realm selected");
  final index = ref
      .read(realmEntryIndexProvider(organizationId, realmId))
      .requireValue;
  final snapshot = ref.read(realmEditorCatalogProvider).requireValue.snapshot;
  if (snapshot == null) throw ApiException.badRequest("Catalog is unavailable");
  final registry = TypeRegistry(
    bootstrapTypeCatalog(snapshot.catalog.definitions),
  );
  final selectedIds = entries.map((entry) => entry.id.id).toSet();
  final sourcePages = _cachedEntries(
    ref,
    entries,
  ).map((entry) => entry.pageId).toSet();
  if (sourcePages.length != 1) {
    throw ApiException.badRequest("Linked entries must belong to one page");
  }
  final sourcePageId = recordId("page:${sourcePages.single}");

  bool accepts(SearchResult result) {
    final payload = result.payload;
    if (payload is! skir.AuthoringSearchElement ||
        selectedIds.contains(payload.id.id)) {
      return false;
    }
    final target = index[payload.id.id];
    if (target == null) return false;
    final targetIdentity = EntryIdentifier(
      target.definition.id,
      elementType: target.definition.elementDefinition.rootType,
    );
    return entries.every(
      (entry) => entry.definition
          .referenceDropValues(targetIdentity, registry)
          .isNotEmpty,
    );
  }

  bool acceptsDefinition(ElementDefinition definition) {
    final candidate = EntryIdentifier(
      "pending",
      elementType: definition.rootType,
    );
    return entries.every(
      (entry) =>
          entry.definition.referenceDropValues(candidate, registry).isNotEmpty,
    );
  }

  return showSearchModal<EntryIdentifier>(
    ref.context,
    (modalRef, promptContext) {
      final policy = modalRef.valued(
        pageEntryCreationPolicyForPageProvider(sourcePageId),
      );
      return SearchContribution(
        session: SearchSession(
          source: [
            RealmAuthoringSearchSource(
              ref: modalRef,
              organizationId: organizationId,
              realmId: realmId,
              referenceOrigins: [
                for (final entry in entries) recordId("element:${entry.id.id}"),
              ],
            ),
            ElementTypeSearchSource(
              definitions: modalRef.valued(
                availableElementDefinitionsFutureProvider,
              ),
            ),
          ].merged(),
          scope: PredicateSearchScope(
            evaluate: (result, query) {
              final visible =
                  accepts(result) ||
                  (result.payload is ElementDefinition &&
                      acceptsDefinition(result.payload as ElementDefinition));
              return visible
                  ? const SearchResultVisibility.visible()
                  : const SearchResultVisibility.hidden();
            },
          ),
          interaction: SearchInteraction(
            activation: SearchActivation.custom(
              dependencies: [policy],
              evaluate: (context, result) {
                if (accepts(result)) {
                  return const SearchActivationState.enabled();
                }
                if (result.payload is! ElementDefinition ||
                    !acceptsDefinition(result.payload as ElementDefinition)) {
                  return const SearchActivationState.hidden();
                }
                final command = context.commands.resolveCommand(
                  createElementOnPageCommandId,
                  result,
                );
                return switch (command?.state) {
                  SearchCommandEnabled() =>
                    const SearchActivationState.enabled(),
                  SearchCommandDisabled(:final reason) =>
                    SearchActivationState.disabled(reason),
                  SearchCommandHidden() ||
                  null => const SearchActivationState.hidden(),
                };
              },
              activate: (context, result) async {
                if (result.payload is ElementDefinition) {
                  return const SearchActivationResult.command(
                    createElementOnPageCommandId,
                  );
                }
                final element = result.payload as skir.AuthoringSearchElement;
                final target = index[element.id.id]!;
                return SearchActivationResult.complete(
                  EntryIdentifier(
                    element.id.id,
                    pageId: element.page.id.id,
                    elementType: target.definition.elementDefinition.rootType,
                  ),
                );
              },
            ),
            selectionMode: SearchSelectionMode.single,
            commands: [
              createElementOnPageCommand(
                ref: modalRef,
                organizationId: organizationId,
                realmId: realmId,
                pageId: sourcePageId,
                policy: policy,
              ),
            ],
          ),
        ),
        hostEffectExecutors: [
          SearchHostEffectExecutor<SelectCreatedElementEffect>((effect) {
            if (effect.pageId != sourcePageId) {
              throw StateError("Created element belongs to another page");
            }
            Navigator.of(promptContext).pop(effect.elementIdentifier);
          }),
        ],
      );
    },
    searchHint: "Choose entry to link",
    rowRenderers: {
      authoringElementSearchResultType.id: (context) =>
          AuthoringElementSearchResultItem(
            element: context.result.payload as skir.AuthoringSearchElement,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      elementTypeSearchResultType.id: buildElementTypeSearchResultItem,
    },
  );
}

Future<void> _linkEntries(
  WidgetRef ref,
  List<EntrySelection> entries,
  EntryIdentifier targetIdentifier,
) async {
  final currentEntries = _cachedEntries(ref, entries);
  final target = _cachedEntryIdentifiers(ref, [targetIdentifier]).single;
  final snapshot = ref.read(realmEditorCatalogProvider).requireValue.snapshot;
  if (snapshot == null) throw ApiException.badRequest("Catalog is unavailable");
  final registry = TypeRegistry(
    bootstrapTypeCatalog(snapshot.catalog.definitions),
  );
  final identity = EntryIdentifier(
    target.definition.id,
    elementType: target.definition.elementDefinition.rootType,
  );
  final candidateMaps = [
    for (final entry in currentEntries)
      entry.definition.referenceDropValues(identity, registry),
  ];
  final commonPaths = candidateMaps
      .map((values) => values.keys.toSet())
      .reduce((left, right) => left.intersection(right));
  if (commonPaths.isEmpty) {
    throw ApiException.conflict("The selected reference fields changed");
  }
  final path = commonPaths.length == 1
      ? commonPaths.single
      : await _selectReferencePath(ref.context, commonPaths);
  if (path == null || !ref.context.mounted) return;
  final sourcePages = currentEntries.map((entry) => entry.pageId).toSet();
  if (sourcePages.length != 1) {
    throw ApiException.badRequest("Linked entries must belong to one page");
  }
  await ref.withReadyPageElements(sourcePages.single, (elements) {
    final latestEntries = _cachedEntries(ref, entries);
    final latestTarget = _cachedEntryIdentifiers(ref, [
      targetIdentifier,
    ]).single;
    final latestIdentity = EntryIdentifier(
      latestTarget.definition.id,
      elementType: latestTarget.definition.elementDefinition.rootType,
    );
    final updates = <String, ({DataPath path, DataValue value})>{};
    for (final source in latestEntries) {
      final value = source.definition.referenceDropValues(
        latestIdentity,
        registry,
      )[path];
      if (value == null) {
        throw ApiException.conflict("The selected reference field changed");
      }
      updates[source.definition.id] = (path: path, value: value);
    }
    return elements.updateEntryFieldValues(updates);
  });
}

Future<DataPath?> _selectReferencePath(
  BuildContext context,
  Set<DataPath> paths,
) => showAdvancedDialog<DataPath>(
  context: context,
  builder: (context) => SimpleDialog(
    title: const Text("Choose reference field"),
    children: [
      for (final path in paths)
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(path),
          child: Text(path.toString()),
        ),
    ],
  ),
);

Future<DataPath?> _selectDuplicateLinkPath(
  WidgetRef ref,
  List<EntrySelection> entries,
) async {
  final snapshot = ref.read(realmEditorCatalogProvider).requireValue.snapshot;
  if (snapshot == null) throw ApiException.badRequest("Catalog is unavailable");
  final registry = TypeRegistry(
    bootstrapTypeCatalog(snapshot.catalog.definitions),
  );
  final candidates = [
    for (final entry in entries)
      entry.definition
          .referenceDropValues(
            EntryIdentifier(
              entry.id.id,
              elementType: entry.definition.elementDefinition.rootType,
            ),
            registry,
          )
          .keys
          .toSet(),
  ];
  if (candidates.isEmpty) return null;
  final common = candidates.reduce((left, right) => left.intersection(right));
  if (common.isEmpty) {
    throw ApiException.conflict("No shared reference field is available");
  }
  if (common.length == 1) return common.single;
  return _selectReferencePath(ref.context, common);
}

void _requireEntriesOnPage(
  WidgetRef ref,
  List<EntrySelection> entries,
  String expectedPageId,
) {
  final current = _cachedEntries(ref, entries);
  if (current.any((entry) => entry.pageId != expectedPageId)) {
    throw ApiException.conflict("An entry moved to another page");
  }
}

Future<Page?> _selectTargetPage(WidgetRef ref, List<Page> pages) {
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  if (organizationId == null) throw ApiException.noOrganization();
  if (realmId == null) throw ApiException.badRequest("No realm selected");
  final byId = {for (final page in pages) page.pageId: page};
  return showSearchModal<Page>(
    ref.context,
    (modalRef, promptContext) => SearchContribution(
      session: SearchSession(
        source: RealmAuthoringSearchSource(
          ref: modalRef,
          organizationId: organizationId,
          realmId: realmId,
        ),
        scope: PredicateSearchScope(
          evaluate: (result, query) => switch (result.payload) {
            skir.AuthoringSearchPage(:final id) when byId.containsKey(id) =>
              const SearchResultVisibility.visible(),
            _ => const SearchResultVisibility.hidden(),
          },
        ),
        interaction: SearchInteraction(
          activation: SearchActivation.custom(
            dependencies: const [],
            evaluate: (context, result) => switch (result.payload) {
              skir.AuthoringSearchPage(:final id) when byId.containsKey(id) =>
                const SearchActivationState.enabled(),
              _ => const SearchActivationState.hidden(),
            },
            activate: (context, result) async =>
                SearchActivationResult.complete(
                  byId[(result.payload as skir.AuthoringSearchPage).id]!,
                ),
          ),
          selectionMode: SearchSelectionMode.single,
        ),
      ),
    ),
    searchHint: "Move to page",
    rowRenderers: {
      authoringPageSearchResultType.id: (context) =>
          AuthoringPageSearchResultItem(
            page: context.result.payload as skir.AuthoringSearchPage,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
    },
  );
}

Future<ElementDefinition?> _selectReplacementType(
  WidgetRef ref,
  EntrySelection entry,
) {
  final pageId = entry.id.pageId;
  if (pageId == null) {
    throw ApiException.badRequest("Entry page is unavailable");
  }
  return showSearchModal<ElementDefinition>(
    ref.context,
    (modalRef, promptContext) {
      final definitions = modalRef.valued(
        availableElementDefinitionsFutureProvider,
      );
      final policy = modalRef.valued(
        pageEntryCreationPolicyForPageProvider(recordId("page:$pageId")),
      );
      return SearchContribution(
        session: SearchSession(
          source: ElementTypeSearchSource(definitions: definitions),
          scope: pageElementTypeScope(policy: policy),
          interaction: SearchInteraction(
            activation: SearchActivation.custom(
              dependencies: [policy],
              evaluate: (context, result) => switch (result.payload) {
                ElementDefinition(:final rootType)
                    when rootType !=
                        entry.definition.elementDefinition.rootType =>
                  const SearchActivationState.enabled(),
                _ => const SearchActivationState.hidden(),
              },
              activate: (context, result) async =>
                  SearchActivationResult.complete(
                    result.payload as ElementDefinition,
                  ),
            ),
            selectionMode: SearchSelectionMode.single,
          ),
        ),
      );
    },
    searchHint: "Replace with element type",
    rowRenderers: {
      elementTypeSearchResultType.id: buildElementTypeSearchResultItem,
    },
  );
}

Future<RecordValue?> _prepareReplacementValue(
  WidgetRef ref,
  EntrySelection entry,
  ElementDefinition replacement,
) async {
  final snapshot = ref.read(realmEditorCatalogProvider).requireValue.snapshot;
  if (snapshot == null) throw ApiException.badRequest("Catalog is unavailable");
  final registry = TypeRegistry(
    bootstrapTypeCatalog(snapshot.catalog.definitions),
  );
  final representation = replacement
      .resolve(registry)
      .valueOrNull
      ?.representation;
  if (representation is! RecordType) {
    throw ApiException.badRequest("Replacement type must be a record");
  }
  final current = entry.definition.data;
  final fixedValues = <MaterializationLocation, DataValue>{};
  final retained = <String>{};
  for (final field in representation.fields.values) {
    final value = current.fields[field.name];
    if (value == null ||
        value.validateAgainst(field.type, registry: registry).isNotEmpty) {
      continue;
    }
    fixedValues[MaterializationLocation(["field:${field.name}"])] = value;
    retained.add(field.name);
  }
  fixedValues[const MaterializationLocation(["field:id"])] = StringValue(
    entry.id.id,
  );
  fixedValues[const MaterializationLocation(["field:name"])] = StringValue(
    entry.name,
  );
  retained.addAll(const ["id", "name"]);

  final draft = CreationDraft(
    rootType: NamedType(replacement.rootType),
    registry: registry,
    fixedValues: fixedValues,
  );
  try {
    final prepared =
        draft.finalize().valueOrNull ??
        await promptElementCreationEditor(
          context: ref.context,
          title: "Replace with ${replacement.name}",
          draft: draft,
          presentations: snapshot.presentations.values.toList(),
          origins: [recordId("element:${entry.id.id}")],
        );
    if (prepared == null || !ref.context.mounted) return null;
    if (prepared is! RecordValue) {
      throw ApiException.badRequest("Replacement value must be a record");
    }
    final discarded = current.fields.keys
        .where((field) => !retained.contains(field))
        .toList(growable: false);
    if (discarded.isNotEmpty) {
      final confirmed = await showAdvancedDialog<bool>(
        context: ref.context,
        builder: (context) => AlertDialog(
          title: const Text("Replace entry type?"),
          content: Text(
            "The following fields cannot be retained: ${discarded.join(", ")}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Replace"),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
    }
    return prepared
        .withField("id", StringValue(entry.id.id))
        .withField("name", StringValue(entry.name));
  } finally {
    draft.dispose();
  }
}

/// Replaces one selected entry type while preserving its resource identity.
class EntryReplaceWithOperation extends ActivatorShortcutOperation {
  const EntryReplaceWithOperation();

  @override
  String get name => "Replace with...";

  @override
  String get description => "Change this entry to another element type";

  Color get color => Colors.orange;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyR),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.length == 1 && selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );
    if (entries.length != 1) {
      throw ApiException.badRequest("Replace with requires one entry");
    }
    final entry = entries.single;
    final replacement = await _selectReplacementType(ref, entry);
    if (replacement == null || !ref.context.mounted) return;
    final value = await _prepareReplacementValue(ref, entry, replacement);
    if (value == null || !ref.context.mounted) return;
    final cached = _cachedEntries(ref, [entry]).single;
    await ref.withReadyPageElements(cached.pageId, (elements) {
      _requireEntriesOnPage(ref, [entry], cached.pageId);
      return elements.replaceEntryType(entry.id.id, replacement, value);
    });
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(MaterialSymbols.find_replace),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(MaterialSymbols.find_replace),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}
