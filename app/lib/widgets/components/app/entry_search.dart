import "package:collection/collection.dart";
import "package:flutter/material.dart" hide Page;
import "package:flutter/services.dart";
import "package:fuzzy/fuzzy.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/smart_single_activator.dart";
import "package:typewriter/widgets/components/app/page_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "entry_search.g.dart";

// Allows an entry if it has any of the tags.
class TagFilter extends SearchFilter {
  const TagFilter(this.tags, {this.canRemove = true});

  final List<String> tags;
  @override
  final bool canRemove;

  @override
  String get title => tags.lastOrNull?.formatted ?? "Tags";
  @override
  Color get color => Colors.deepOrangeAccent;
  @override
  String get icon => TWIcons.hashtag;

  @override
  bool filter(SearchElement action) {
    final blueprint = switch (action) {
      final EntrySearchElement entry => entry.blueprint,
      final AddEntrySearchElement entry => entry.blueprint,
      _ => null,
    };

    if (blueprint == null) return true;
    return blueprint.tags.containsAny(tags);
  }
}

class AddOnlyTagFilter extends TagFilter {
  const AddOnlyTagFilter(super.tags, {super.canRemove = true});

  @override
  bool filter(SearchElement action) {
    if (action is AddEntrySearchElement) {
      return action.blueprint.tags.containsAny(tags);
    }
    return true;
  }
}

class ExcludeEntryFilter extends HiddenSearchFilter {
  const ExcludeEntryFilter(this.entryId, {this.canRemove = true});

  final String entryId;
  @override
  final bool canRemove;

  @override
  String get title => "Exclude Entry";

  @override
  Color get color => Colors.orange;

  @override
  String get icon => TWIcons.file;

  @override
  bool filter(SearchElement action) {
    if (action is EntrySearchElement) {
      return action.entry.id != entryId;
    }
    return true;
  }
}

class GenericEntryFilter extends SearchFilter {
  const GenericEntryFilter(this.blueprint, {this.canRemove = true});

  final DataBlueprint blueprint;
  @override
  final bool canRemove;

  @override
  String get title => "Generic";

  @override
  Color get color => Colors.green;

  @override
  String get icon => TWIcons.asterisk;

  @override
  bool filter(SearchElement action) {
    if (action is EntrySearchElement) {
      if (action.entry.genericBlueprint == null) return true;
      return action.entry.genericBlueprint!.matches(blueprint);
    }
    if (action is AddEntrySearchElement) {
      return action.blueprint.allowsGeneric(blueprint);
    }
    return true;
  }
}

class NonGenericAddEntryFilter extends HiddenSearchFilter {
  const NonGenericAddEntryFilter({this.canRemove = true});

  @override
  final bool canRemove;

  @override
  String get title => "Non-Generic";

  @override
  Color get color => Colors.red;

  @override
  String get icon => TWIcons.blocked;

  @override
  bool filter(SearchElement action) {
    if (action is AddEntrySearchElement) {
      return !action.blueprint.isGeneric;
    }
    return true;
  }
}

@riverpod
Fuzzy<EntryDefinition> _fuzzyEntries(Ref ref) {
  final pages = ref.watch(pagesProvider);
  final definitions = pages.expand((page) {
    return page.entries.map((entry) {
      final blueprint = ref.watch(entryBlueprintProvider(entry.blueprintId));
      if (blueprint == null) return null;
      return EntryDefinition(
        pageId: page.id,
        pageName: page.pageName,
        blueprint: blueprint,
        entry: entry,
      );
    }).nonNulls;
  }).toList();

  return Fuzzy(
    definitions,
    options: FuzzyOptions(
      threshold: 0.4,
      sortFn: (a, b) => a.matches
          .map((e) => e.score)
          .sum
          .compareTo(b.matches.map((e) => e.score).sum),
      // tokenize: true,
      // verbose: true,
      keys: [
        // The names of entries are like "test.some_entry".
        // We want to give the last part more priority since it is more specific.
        WeightedKey(
          name: "name-suffix",
          getter: (definition) => definition.entry.name.split(".").last,
          weight: 0.4,
        ),
        WeightedKey(
          name: "name-full",
          getter: (definition) => definition.entry.name.formatted,
          weight: 0.15,
        ),
        WeightedKey(
          name: "blueprint",
          getter: (definition) => definition.blueprint.name.formatted,
          weight: 0.4,
        ),
        WeightedKey(
          name: "tags",
          getter: (definition) => definition.blueprint.tags.join(" "),
          weight: 0.3,
        ),
        WeightedKey(
          name: "extension",
          getter: (definition) => definition.blueprint.extension,
          weight: 0.1,
        ),
        WeightedKey(
          name: "id",
          getter: (definition) => definition.entry.id,
          weight: 0.1,
        ),
      ],
    ),
  );
}

@riverpod
Fuzzy<EntryBlueprint> _fuzzyBlueprints(Ref ref) {
  // If the blueprint has the "deprecated" tag, we don't want to show it.
  final blueprints = ref
      .watch(entryBlueprintsProvider)
      .where(
        (blueprint) => blueprint.modifiers.none((e) => e is DeprecatedModifier),
      )
      .toList();

  return Fuzzy(
    blueprints,
    options: FuzzyOptions(
      threshold: 0.3,
      sortFn: (a, b) => a.matches
          .map((e) => e.score)
          .sum
          .compareTo(b.matches.map((e) => e.score).sum),
      keys: [
        WeightedKey(
          name: "name",
          getter: (blueprint) => "Add ${blueprint.name.formatted}",
          weight: 0.5,
        ),
        WeightedKey(
          name: "tags",
          getter: (blueprint) => blueprint.tags.join(" "),
          weight: 0.2,
        ),
        WeightedKey(
          name: "description",
          getter: (blueprint) => blueprint.description,
          weight: 0.4,
        ),
        WeightedKey(
          name: "extension",
          getter: (blueprint) => blueprint.extension,
          weight: 0.2,
        ),
      ],
    ),
  );
}

class NewEntryFetcher extends SearchFetcher {
  const NewEntryFetcher({
    this.genericBlueprint,
    this.onAdd,
    this.onAdded,
    this.disabled = false,
  });

  final DataBlueprint? genericBlueprint;
  final FutureOr<bool?> Function(EntryBlueprint)? onAdd;
  final FutureOr<bool?> Function(Entry)? onAdded;

  @override
  final bool disabled;

  @override
  String get title => "New Entries";

  @override
  List<String> get quantifiers => [
        "e",
        "ne",
        "ae",
        "ea",
        "entry",
        "entries",
        "add",
        "add_entry",
        "add_entries",
        "entry_add",
        "entries_add",
        "new",
        "new_entry",
        "new_entries",
      ];

  @override
  List<SearchElement> fetch(PassingRef ref, String query) {
    final fuzzy = ref.read(_fuzzyBlueprintsProvider);

    final results = fuzzy.search(query);

    return results
        .map(
          (result) => AddEntrySearchElement(
            result.item,
            genericBlueprint: genericBlueprint,
            onAdd: onAdd,
            onAdded: onAdded,
          ),
        )
        .toList();
  }

  @override
  SearchFetcher copyWith({
    bool? disabled,
  }) {
    return NewEntryFetcher(
      genericBlueprint: genericBlueprint,
      onAdd: onAdd,
      onAdded: onAdded,
      disabled: disabled ?? this.disabled,
    );
  }
}

class EntryFetcher extends SearchFetcher {
  const EntryFetcher({
    this.onSelect,
    this.disabled = false,
  });

  final FutureOr<bool?> Function(Entry)? onSelect;

  @override
  final bool disabled;

  @override
  String get title => "Entries";

  @override
  List<String> get quantifiers =>
      ["e", "ee", "entry", "entries", "existing_entry", "existing_entries"];

  @override
  List<SearchElement> fetch(PassingRef ref, String query) {
    final fuzzy = ref.read(_fuzzyEntriesProvider);

    final results = fuzzy.search(query);

    return results.map((result) {
      final definition = result.item;
      return EntrySearchElement(definition, onSelect: onSelect);
    }).toList();
  }

  @override
  SearchFetcher copyWith({
    bool? disabled,
  }) {
    return EntryFetcher(
      onSelect: onSelect,
      disabled: disabled ?? this.disabled,
    );
  }
}

extension SearchBuilderX on SearchBuilder {
  void tag(String tag, {bool canRemove = true}) {
    filter(TagFilter([tag], canRemove: canRemove));
  }

  void anyTag(List<String> tags, {bool canRemove = true}) {
    filter(TagFilter(tags, canRemove: canRemove));
  }

  void addOnlyTag(String tag, {bool canRemove = true}) {
    filter(AddOnlyTagFilter([tag], canRemove: canRemove));
  }

  void addOnlyAnyTag(List<String> tags, {bool canRemove = true}) {
    filter(AddOnlyTagFilter(tags, canRemove: canRemove));
  }

  void excludeEntry(String entryId, {bool canRemove = true}) {
    filter(ExcludeEntryFilter(entryId, canRemove: canRemove));
  }

  void genericEntry(DataBlueprint blueprint, {bool canRemove = false}) {
    filter(GenericEntryFilter(blueprint, canRemove: canRemove));
  }

  void nonGenericAddEntry({bool canRemove = false}) {
    filter(NonGenericAddEntryFilter(canRemove: canRemove));
  }

  void fetchNewEntry({
    DataBlueprint? genericBlueprint,
    FutureOr<bool?> Function(EntryBlueprint)? onAdd,
    FutureOr<bool?> Function(Entry)? onAdded,
  }) {
    fetch(
      NewEntryFetcher(
        genericBlueprint: genericBlueprint,
        onAdd: onAdd,
        onAdded: onAdded,
      ),
    );
  }

  void fetchEntry({FutureOr<bool?> Function(Entry)? onSelect}) {
    fetch(EntryFetcher(onSelect: onSelect));
  }
}

/// Action for selecting an existing entry.
class EntrySearchElement extends SearchElement {
  const EntrySearchElement(this.definition, {this.onSelect});
  final EntryDefinition definition;
  final FutureOr<bool?> Function(Entry)? onSelect;

  EntryBlueprint get blueprint => definition.blueprint;
  Entry get entry => definition.entry;

  @override
  String get title => entry.formattedName;

  @override
  Color color(BuildContext context) => blueprint.color;

  @override
  Widget icon(BuildContext context) => Iconify(blueprint.icon);

  @override
  Widget suffixIcon(BuildContext context) =>
      const Iconify(TWIcons.externalLink);

  @override
  String description(BuildContext context) => definition.pageName.formatted;

  @override
  List<SearchAction> actions(PassingRef ref) {
    return [
      const SearchAction(
        "Open",
        TWIcons.externalLink,
        SingleActivator(LogicalKeyboardKey.enter),
      ),
      SearchAction(
        "Open Wiki",
        TWIcons.book,
        SmartSingleActivator(LogicalKeyboardKey.keyO, control: true),
        onTrigger: (_, __) {
          blueprint.openWiki();
          return false;
        },
      ),
    ];
  }

  @override
  Future<bool> activate(BuildContext context, PassingRef ref) async {
    if (onSelect != null) {
      return await onSelect?.call(entry) ?? true;
    }

    await ref
        .read(inspectingEntryIdProvider.notifier)
        .navigateAndSelectEntry(ref, entry.id);
    return true;
  }
}

class AddEntrySearchElement extends SearchElement {
  const AddEntrySearchElement(
    this.blueprint, {
    this.genericBlueprint,
    this.onAdd,
    this.onAdded,
  });
  final EntryBlueprint blueprint;
  final DataBlueprint? genericBlueprint;
  final FutureOr<bool?> Function(EntryBlueprint)? onAdd;
  final FutureOr<bool?> Function(Entry)? onAdded;

  @override
  String get title => "Add ${blueprint.name.formatted}";

  @override
  Color color(BuildContext context) => blueprint.color;

  @override
  Widget icon(BuildContext context) =>
      Iconify(blueprint.icon, color: Theme.of(context).scaffoldBackgroundColor);

  @override
  Widget suffixIcon(BuildContext context) => const Iconify(TWIcons.plus);

  @override
  String description(BuildContext context) => blueprint.description;

  @override
  List<SearchAction> actions(PassingRef ref) {
    return [
      const SearchAction(
        "Add",
        TWIcons.plus,
        SingleActivator(LogicalKeyboardKey.enter),
      ),
      SearchAction(
        "Open Wiki",
        TWIcons.book,
        SmartSingleActivator(LogicalKeyboardKey.keyO, control: true),
        onTrigger: (_, __) {
          blueprint.openWiki();
          return false;
        },
      ),
    ];
  }

  @override
  Future<bool> activate(BuildContext context, PassingRef ref) async {
    if (onAdd != null) {
      return await onAdd?.call(blueprint) ?? true;
    }
    final page = ref.read(currentPageProvider);
    if (page != null && page.canHave(blueprint)) {
      return _createAndNavigate(ref, page, blueprint);
    }

    // This page can't have the entry, so we need to select/create a new page where we can.

    ref.read(searchProvider.notifier).asBuilder()
      ..pageType(PageType.fromBlueprint(blueprint))
      ..fetchPage(onSelect: (page) => _createAndNavigate(ref, page, blueprint))
      ..fetchAddPage(
        onAdded: (page) => _createAndNavigate(ref, page, blueprint),
      )
      ..open();

    return false;
  }

  Future<bool> _createAndNavigate(
    PassingRef ref,
    Page page,
    EntryBlueprint blueprint,
  ) async {
    final entry = await page.createEntryFromBlueprint(
      ref,
      blueprint,
      genericBlueprint: genericBlueprint,
    );
    onAdded?.call(entry);
    final notifier = ref.read(inspectingEntryIdProvider.notifier);

    final currentPage = ref.read(currentPageProvider);
    // Had to create/select a new page for the entry
    if (page.id != currentPage?.id) {
      ref.read(searchProvider.notifier).endSearch();
    }

    await notifier.navigateAndSelectEntry(ref, entry.id);
    return true;
  }
}
