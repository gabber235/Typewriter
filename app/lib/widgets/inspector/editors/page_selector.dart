import "package:flutter/material.dart" hide Page;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/pages_list.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/smart_single_activator.dart";
import "package:typewriter/widgets/components/app/page_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class PageSelectorEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is PrimitiveBlueprint &&
      dataBlueprint.type == PrimitiveType.string &&
      dataBlueprint.hasModifier("page");

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => PageSelectorEditor(
        path: path,
        primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
      );
}

class PageSelectorEditor extends HookConsumerWidget {
  const PageSelectorEditor({
    required this.path,
    required this.primitiveBlueprint,
    super.key,
  });
  final String path;

  final PrimitiveBlueprint primitiveBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final typeTag = primitiveBlueprint.get("page");
    final type = typeTag == null ? null : PageType.fromName(typeTag);

    if (type == null) {
      return Text(l10n.invalidPageType);
    }

    final pageId =
        ref.watch(fieldValueProvider(path, primitiveBlueprint.defaultValue()));
    final hasPage = ref.watch(pageExistsProvider(pageId));

    return DragTarget<PageDrag>(
      onWillAcceptWithDetails: (details) {
        if (details.data.pageId == pageId) return false;
        final targetType = ref.read(pageTypeProvider(details.data.pageId));

        return targetType == type;
      },
      onAcceptWithDetails: (details) {
        ref
            .read(inspectingEntryDefinitionProvider)
            ?.updateField(ref.passing, path, details.data.pageId);
      },
      builder: (context, candidateData, rejectedData) {
        if (rejectedData.isNotEmpty) {
          return _rejectWidget(context);
        }

        final isAccepting = candidateData.isNotEmpty;

        final needsPadding = !hasPage && !isAccepting;

        return Material(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(8),
          child: ContextMenuRegion(
            builder: (context) {
              return [
                if (hasPage) ...[
                  ContextMenuTile.button(
                    title: l10n.navigateToEntry,
                    icon: TWIcons.pencil,
                    onTap: () {
                      ref.read(appRouter).navigateToPage(ref.passing, pageId);
                    },
                  ),
                  ContextMenuTile.button(
                    title: l10n.deleteReference,
                    icon: TWIcons.squareMinus,
                    color: Colors.redAccent,
                    onTap: () {
                      ref
                          .read(inspectingEntryDefinitionProvider)
                          ?.updateField(ref.passing, path, "");
                    },
                  ),
                ],
                if (!hasPage) ...[
                  ContextMenuTile.button(
                    title: l10n.selectEntry,
                    icon: TWIcons.magnifyingGlass,
                    onTap: () {
                      _select(ref.passing, type);
                    },
                  ),
                ],
              ];
            },
            child: InkWell(
              onTap: () {
                if (hasOverrideDown && hasPage) {
                  ref.read(appRouter).navigateToPage(ref.passing, pageId);
                  return;
                }
                _select(ref.passing, type);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.only(
                  left: needsPadding ? 12 : 4,
                  right: 16,
                  top: needsPadding ? 12 : 4,
                  bottom: needsPadding ? 12 : 4,
                ),
                child: Row(
                  children: [
                    if (!hasPage && !isAccepting) ...[
                      Iconify(
                        TWIcons.database,
                        size: 16,
                        color: Theme.of(context)
                            .inputDecorationTheme
                            .hintStyle
                            ?.color,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (isAccepting)
                      Expanded(
                        child: Opacity(
                          opacity: 0.5,
                          child: _SelectedPage(id: candidateData.first!.pageId),
                        ),
                      )
                    else if (hasPage)
                      Expanded(child: _SelectedPage(id: pageId))
                    else
                      Expanded(
                        child: Text(
                          l10n.selectAPage(type.tag),
                          style:
                              Theme.of(context).inputDecorationTheme.hintStyle,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Iconify(
                      TWIcons.caretDown,
                      size: 16,
                      color: Theme.of(context)
                          .inputDecorationTheme
                          .hintStyle
                          ?.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rejectWidget(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Iconify(
              TWIcons.x,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.pageNotAllowedHere,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _select(PassingRef ref, PageType type) {
    ref.read(searchProvider.notifier).asBuilder()
      ..pageType(type)
      ..fetchPage(onSelect: (page) => _update(ref, page))
      ..fetchAddPage(onAdded: (page) => _update(ref, page))
      ..open();
  }

  bool _update(PassingRef ref, Page? page) {
    if (page == null) return false;
    ref
        .read(inspectingEntryDefinitionProvider)
        ?.updateField(ref, path, page.id);
    return true;
  }
}

class _SelectedPage extends HookConsumerWidget {
  const _SelectedPage({
    required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageType = ref.watch(pageTypeProvider(id));
    final chapter = ref.watch(pageChapterProvider(id));
    final pageName = ref.watch(pageNameProvider(id)) ?? "";
    return Material(
      borderRadius: BorderRadius.circular(4),
      color: pageType.color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Iconify(pageType.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pageName.formatted,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (chapter.isNotEmpty)
                    Text(
                      chapter.formatted,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
