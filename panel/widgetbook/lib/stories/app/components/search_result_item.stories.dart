import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/widgets/app/components/search_result_item/search_result_item.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Catalog", type: SearchResultCard)
Widget searchResultItemCatalogUseCase(BuildContext context) {
  final cardColor = Theme.of(context).colorScheme.surfaceContainerLow;
  return FakeApp(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Surface(
          color: cardColor,
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: HookBuilder(
                builder: (context) {
                  final selectedIndex = useState(0);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Text(
                        "Search result list items",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final (index, item) in _items().indexed)
                        _SelectableItem(
                          selected: selectedIndex.value == index,
                          onTap: () {
                            selectedIndex.value = index;
                          },
                          child: item,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Entry", type: EntrySearchResultItem)
Widget entrySearchResultItemUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _items()[0],
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Blueprint", type: BlueprintSearchResultItem)
Widget blueprintSearchResultItemUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _items()[1],
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Page", type: PageSearchResultItem)
Widget pageSearchResultItemUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _items()[3],
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Book", type: BookSearchResultItem)
Widget bookSearchResultItemUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _items()[5],
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Tag", type: TagSearchResultItem)
Widget tagSearchResultItemUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _items()[7],
      ),
    ),
  );
}

List<Widget> _items() {
  return [
    EntrySearchResultItem(
      name: "winston_dialogue",
      blueprintName: "spoken",
      bookTitle: "main_quest",
      chapter: "main_quest.quests.welcome",
      pageTitle: "welcome_static",
      color: const Color(0xFF00A6FF),
      icon: "fa6-solid:comments",
      tags: const ["quest", "npc"],
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit1, meta: true),
    ),
    BlueprintSearchResultItem(
      name: "permanent_fact",
      extensionName: "basic",
      shortDescription: "Creates branching player conversations",
      color: const Color(0xFF8B5CF6),
      icon: "fa6-solid:diagram-project",
      tags: const ["interaction", "npc"],
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit2, meta: true),
    ),
    BlueprintSearchResultItem(
      name: "message_blueprint",
      extensionName: "basic",
      shortDescription: "Sends messages to players",
      color: const Color(0xFF8B5CF6),
      icon: "fa6-solid:message",
      tags: const ["chat"],
      focused: true,
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit3, meta: true),
    ),
    PageSearchResultItem(
      name: "market_day",
      bookName: "town_book",
      chapter: "main_quest.quests.welcome",
      color: const Color(0xFFFFB020),
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit4, meta: true),
    ),
    PageSearchResultItem(
      name: "graveyard",
      bookName: "town_book",
      chapter: "main_quest.quests.graveyard",
      color: const Color(0xFFFFB020),
      focused: true,
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit5, meta: true),
    ),
    BookSearchResultItem(
      name: "starter_book",
      color: const Color(0xFF22C55E),
      tags: const ["main", "onboarding"],
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit6, meta: true),
    ),
    BookSearchResultItem(
      name: "town_book",
      color: const Color(0xFF22C55E),
      tags: const ["side", "town"],
      focused: true,
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit7, meta: true),
    ),
    TagSearchResultItem(
      name: "quest",
      color: const Color(0xFFEF4444),
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit8, meta: true),
    ),
    TagSearchResultItem(
      name: "dialogue",
      color: const Color(0xFFEF4444),
      focused: true,
      shortcutActivator: SingleActivator(LogicalKeyboardKey.digit9, meta: true),
    ),
    EntrySearchResultItem(
      name: "my_option",
      blueprintName: "option",
      bookTitle: "starter_book",
      chapter: "",
      pageTitle: "sequence",
      color: safeColors[5],
      icon: "fa6-solid:list-ol",
      tags: const ["sequence", "trigger", "triggerable", "dialogue"],
      focused: true,
    ),

    EntrySearchResultItem(
      name: "Legacy Zombie Objective",
      blueprintName: "Objective Entry",
      bookTitle: "Town Book",
      chapter: "main_quest.quests.graveyard",
      pageTitle: "Graveyard",
      color: const Color(0xFF64748B),
      icon: "fa6-solid:skull",
      tags: const ["combat"],
      deprecated: true,
    ),
  ];
}

class _SelectableItem extends StatelessWidget {
  const _SelectableItem({
    required this.selected,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return switch (child) {
      final EntrySearchResultItem item => EntrySearchResultItem(
        name: item.name,
        blueprintName: item.blueprintName,
        bookTitle: item.bookTitle,
        chapter: item.chapter,
        pageTitle: item.pageTitle,
        color: item.color,
        icon: item.icon,
        tags: item.tags,
        deprecated: item.deprecated,
        selected: selected,
        focused: item.focused,
        onTap: onTap ?? item.onTap,
        onLongPress: onLongPress ?? item.onLongPress,
        shortcutActivator: item.shortcutActivator,
      ),
      final BlueprintSearchResultItem item => BlueprintSearchResultItem(
        name: item.name,
        extensionName: item.extensionName,
        shortDescription: item.shortDescription,
        color: item.color,
        icon: item.icon,
        tags: item.tags,
        deprecated: item.deprecated,
        selected: selected,
        focused: item.focused,
        onTap: onTap ?? item.onTap,
        onLongPress: onLongPress ?? item.onLongPress,
        shortcutActivator: item.shortcutActivator,
      ),
      final PageSearchResultItem item => PageSearchResultItem(
        name: item.name,
        bookName: item.bookName,
        chapter: item.chapter,
        color: item.color,
        icon: item.icon,
        selected: selected,
        focused: item.focused,
        onTap: onTap ?? item.onTap,
        onLongPress: onLongPress ?? item.onLongPress,
        shortcutActivator: item.shortcutActivator,
      ),
      final BookSearchResultItem item => BookSearchResultItem(
        name: item.name,
        color: item.color,
        icon: item.icon,
        tags: item.tags,
        selected: selected,
        focused: item.focused,
        onTap: onTap ?? item.onTap,
        onLongPress: onLongPress ?? item.onLongPress,
        shortcutActivator: item.shortcutActivator,
      ),
      final TagSearchResultItem item => TagSearchResultItem(
        name: item.name,
        color: item.color,
        icon: item.icon,
        selected: selected,
        focused: item.focused,
        onTap: onTap ?? item.onTap,
        onLongPress: onLongPress ?? item.onLongPress,
        shortcutActivator: item.shortcutActivator,
      ),
      _ => child,
    };
  }
}
