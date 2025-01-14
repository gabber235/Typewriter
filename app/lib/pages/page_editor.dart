import "package:auto_route/auto_route.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart" hide Page, SearchBar;
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/smart_single_activator.dart";
import "package:typewriter/widgets/components/app/cinematic_view.dart";
import "package:typewriter/widgets/components/app/entries_graph.dart";
import "package:typewriter/widgets/components/app/manifest_view.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/app/staging.dart";
import "package:typewriter/widgets/components/app/static_entries_list.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/components/general/identifier.dart";
import "package:typewriter/widgets/components/general/shortcut_label.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "page_editor.g.dart";

@Riverpod(keepAlive: true)
String? currentPageId(Ref ref) {
  final routeData = ref.watch(currentRouteDataProvider(PageEditorRoute.name));
  return routeData?.pathParams.getString("id");
}

@riverpod
String currentPageLabel(Ref ref) {
  return ref.watch(currentPageProvider)?.pageName.formatted ?? "";
}

@riverpod
Page? currentPage(Ref ref) {
  final id = ref.watch(currentPageIdProvider);
  final pages = ref.watch(pagesProvider);

  return pages.firstWhereOrNull((element) => element.id == id);
}

@riverpod
PageType? currentPageType(Ref ref) {
  return ref.watch(currentPageProvider.select((page) => page?.type));
}

@RoutePage(name: "PageEditorRoute")
class PageEditor extends HookConsumerWidget {
  const PageEditor({
    @PathParam("id") required this.id,
    super.key,
  });

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const Column(
        children: [
          _AppBar(key: Key("appBar")),
          Divider(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PageContent(),
                ),
                VerticalDivider(),
                _Inspector(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@riverpod
List<Writer> _writers(Ref ref) {
  final pageId = ref.watch(currentPageIdProvider);
  return ref
      .watch(writersProvider)
      .where((writer) => writer.pageId == pageId)
      .toList();
}

class _AppBar extends HookConsumerWidget {
  const _AppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageType = ref.watch(currentPageTypeProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Iconify(pageType?.icon, size: 16),
          const SizedBox(width: 8),
          Text(ref.watch(currentPageLabelProvider)),
          const SizedBox(width: 20),
          Identifier(id: ref.watch(currentPageIdProvider) ?? ""),
          const Spacer(),
          Writers(writers: ref.watch(_writersProvider)),
          const SizedBox(width: 20),
          const StagingIndicator(key: Key("staging-indicator")),
          const SizedBox(width: 20),
          const _SearchBar(),
          const SizedBox(width: 5),
          const _AddEntryButton(),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _SearchBar extends HookConsumerWidget {
  const _SearchBar() : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Actions.invoke(context, SearchIntent()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              children: [
                const Iconify(
                  TWIcons.magnifyingGlass,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 5),
                const Text("Search", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 50),
                ShortcutLabel(
                  activator: SmartSingleActivator(
                    LogicalKeyboardKey.keyK,
                    control: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _AddEntryButton extends HookConsumerWidget {
  const _AddEntryButton() : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      iconSize: 16,
      padding: EdgeInsets.zero,
      icon: const Iconify(TWIcons.plus),
      onPressed: () => ref.read(searchProvider.notifier).startAddSearch(),
    );
  }
}

class _Inspector extends HookConsumerWidget {
  const _Inspector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageId = ref
        .watch(inspectingEntryDefinitionProvider.select((def) => def?.pageId));
    if (pageId == null) {
      return const SizedBox();
    }
    final pageType = ref.watch(pageTypeProvider(pageId));

    switch (pageType) {
      case PageType.sequence || PageType.static || PageType.manifest:
        return const GenericInspector();
      case PageType.cinematic:
        return const CinematicInspector();
    }
  }
}

class _PageContent extends HookConsumerWidget {
  const _PageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageType = ref.watch(currentPageTypeProvider);
    if (pageType == null) {
      return const SizedBox();
    }

    switch (pageType) {
      case PageType.sequence:
        return const EntriesGraph();
      case PageType.static:
        return const StaticEntriesList();
      case PageType.cinematic:
        return const CinematicView();
      case PageType.manifest:
        return const ManifestView();
    }
  }
}
