import "package:collection/collection.dart";
import "package:flutter/material.dart" hide Page;
import "package:flutter/services.dart";
import "package:fuzzy/fuzzy.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/pages_list.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/smart_single_activator.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/iconify.dart";

part "page_search.g.dart";

class PageTypeFiler extends SearchFilter {
  const PageTypeFiler(this.type, {this.canRemove = true});

  final PageType type;
  @override
  final bool canRemove;

  @override
  String get title => type.name;
  @override
  Color get color => type.color;
  @override
  String get icon => type.icon;

  @override
  bool filter(SearchElement action) {
    if (action is PageSearchElement) {
      return action.page.type == type;
    }
    if (action is AddPageSearchElement) {
      return action.type == type;
    }
    return true;
  }
}

@riverpod
Fuzzy<Page> _fuzzyPages(Ref ref) {
  final pages = ref.watch(pagesProvider);
  return Fuzzy(
    pages,
    options: FuzzyOptions(
      threshold: 0.4,
      sortFn: (a, b) => a.matches
          .map((e) => e.score)
          .sum
          .compareTo(b.matches.map((e) => e.score).sum),
      keys: [
        WeightedKey(
          name: "name",
          weight: 0.6,
          getter: (page) => page.pageName.formatted,
        ),
        WeightedKey(
          name: "chapter",
          weight: 0.4,
          getter: (page) => page.chapter.formatted,
        ),
        WeightedKey(
          name: "type",
          weight: 0.2,
          getter: (page) => page.type.name,
        ),
      ],
    ),
  );
}

class PageFetcher extends SearchFetcher {
  const PageFetcher({
    this.onSelect,
    this.disabled = false,
  });

  final FutureOr<bool?> Function(Page)? onSelect;

  @override
  final bool disabled;

  @override
  String get title => "Pages";

  @override
  List<String> get quantifiers =>
      ["p", "ep", "page", "pages", "existing_page", "existing_pages"];

  @override
  List<SearchElement> fetch(PassingRef ref, String query) {
    final fuzzy = ref.read(_fuzzyPagesProvider);

    final results = fuzzy.search(query);

    return results.map((result) {
      return PageSearchElement(
        result.item,
        onSelect: onSelect,
      );
    }).toList();
  }

  @override
  SearchFetcher copyWith({bool? disabled}) {
    return PageFetcher(
      onSelect: onSelect,
      disabled: disabled ?? this.disabled,
    );
  }
}

@riverpod
Fuzzy<PageType> _fuzzyPageTypes(Ref ref) {
  const types = PageType.values;
  return Fuzzy(
    types,
    options: FuzzyOptions(
      threshold: 0.4,
      sortFn: (a, b) => a.matches
          .map((e) => e.score)
          .sum
          .compareTo(b.matches.map((e) => e.score).sum),
      keys: [
        WeightedKey(
          name: "name",
          weight: 1,
          getter: (type) => type.name,
        ),
      ],
    ),
  );
}

class AddPageFetcher extends SearchFetcher {
  AddPageFetcher({this.onAdded, this.disabled = false});

  final void Function(Page)? onAdded;

  @override
  final bool disabled;

  @override
  String get title => "Add Page";

  @override
  List<String> get quantifiers => [
        "p",
        "page",
        "pages",
        "np",
        "ap",
        "pa",
        "add",
        "add_page",
        "add_pages",
        "page_add",
        "pages_add",
        "new",
        "new_page",
        "new_pages",
      ];

  @override
  List<SearchElement> fetch(PassingRef ref, String query) {
    final fuzzy = ref.read(_fuzzyPageTypesProvider);

    final results = fuzzy.search(query);

    return results.map((result) {
      return AddPageSearchElement(result.item, onAdded: onAdded);
    }).toList();
  }

  @override
  SearchFetcher copyWith({bool? disabled}) {
    return AddPageFetcher(
      onAdded: onAdded,
      disabled: disabled ?? this.disabled,
    );
  }
}

extension SearchBuilderX on SearchBuilder {
  void pageType(PageType type, {bool canRemove = false}) {
    filter(PageTypeFiler(type, canRemove: canRemove));
  }

  void fetchPage({FutureOr<bool?> Function(Page)? onSelect}) {
    fetch(PageFetcher(onSelect: onSelect));
  }

  void fetchAddPage({void Function(Page)? onAdded}) {
    fetch(AddPageFetcher(onAdded: onAdded));
  }
}

class PageSearchElement extends SearchElement {
  const PageSearchElement(this.page, {this.onSelect});

  final Page page;
  final FutureOr<bool?> Function(Page)? onSelect;

  @override
  String get title => page.pageName.formatted;

  @override
  String description(BuildContext context) {
    if (page.chapter.isEmpty) return page.type.name;
    return "~${page.chapter}";
  }

  @override
  Widget icon(BuildContext context) => Iconify(page.type.icon);

  @override
  Color color(BuildContext context) => page.type.color;

  @override
  Widget suffixIcon(BuildContext context) =>
      const Iconify(TWIcons.externalLink);

  @override
  List<SearchAction> actions(PassingRef ref) {
    return [
      const SearchAction(
        "Open",
        TWIcons.externalLink,
        SingleActivator(LogicalKeyboardKey.enter),
      ),
      SearchAction(
        "Rename",
        TWIcons.pencil,
        SmartSingleActivator(LogicalKeyboardKey.keyR, control: true),
        onTrigger: (context, __) async =>
            await showDialog<bool>(
              context: context,
              builder: (_) =>
                  RenamePageDialogue(pageId: page.id, oldName: page.pageName),
            ) ??
            false,
      ),
      SearchAction(
        "Change Chapter",
        TWIcons.bookMarker,
        SmartSingleActivator(LogicalKeyboardKey.keyC, control: true),
        onTrigger: (context, __) async =>
            await showDialog<bool>(
              context: context,
              builder: (_) => ChangeChapterDialogue(
                pageId: page.id,
                chapter: page.chapter,
              ),
            ) ??
            false,
      ),
      SearchAction(
        "Delete",
        TWIcons.trash,
        SmartSingleActivator(LogicalKeyboardKey.backspace, control: true),
        color: Colors.red,
        onTrigger: (context, ref) =>
            showPageDeletionDialogue(context, ref, page.id),
      ),
    ];
  }

  @override
  Future<bool> activate(BuildContext context, PassingRef ref) async {
    if (onSelect != null) {
      return await onSelect?.call(page) ?? true;
    }

    final navigator = ref.read(appRouter);

    ref.read(searchProvider.notifier).endSearch();

    await navigator.navigateToPage(ref, page.id);
    return false;
  }
}

class AddPageSearchElement extends SearchElement {
  const AddPageSearchElement(this.type, {this.onAdded});

  final PageType type;
  final void Function(Page)? onAdded;

  @override
  String get title => "Add ${type.name}";

  @override
  String description(BuildContext context) => "Create a new ${type.name}";

  @override
  Widget icon(BuildContext context) => Iconify(type.icon);

  @override
  Color color(BuildContext context) => type.color;

  @override
  Widget suffixIcon(BuildContext context) => const Icon(Icons.add);

  @override
  List<SearchAction> actions(PassingRef ref) {
    return [
      const SearchAction(
        "Add",
        TWIcons.plus,
        SingleActivator(LogicalKeyboardKey.enter),
      ),
    ];
  }

  @override
  Future<bool> activate(BuildContext context, PassingRef ref) async {
    final pageId = await showDialog<String>(
      context: context,
      builder: (context) =>
          AddPageDialogue(fixedType: type, autoNavigate: false),
    );

    if (pageId == null) return false;
    final page = ref.read(pageProvider(pageId));
    if (page == null) return false;

    if (onAdded != null) {
      onAdded?.call(page);
    }

    await ref.read(appRouter).navigateToPage(ref, pageId);
    return true;
  }
}
