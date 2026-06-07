import "package:collapsible/collapsible.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/boolean.dart";
import "package:typewriter/widgets/inspector/editors/closed_range.dart";
import "package:typewriter/widgets/inspector/headers/colored_action.dart";
import "package:typewriter/widgets/inspector/headers/content_mode_action.dart";
import "package:typewriter/widgets/inspector/headers/help_action.dart";
import "package:typewriter/widgets/inspector/headers/length_action.dart";
import "package:typewriter/widgets/inspector/headers/list_action.dart";
import "package:typewriter/widgets/inspector/headers/map_action.dart";
import "package:typewriter/widgets/inspector/headers/placeholder_action.dart";
import "package:typewriter/widgets/inspector/headers/regex_action.dart";
import "package:typewriter/widgets/inspector/headers/skin_action.dart";
import "package:typewriter/widgets/inspector/headers/variable_action.dart";
import "package:typewriter/widgets/inspector/inspector.dart";
import "package:typewriter/widgets/inspector/section_title.dart";

part "header.freezed.dart";
part "header.g.dart";

@riverpod
Map<String, HeaderActions> headerActions(Ref ref) {
  final blueprint = ref.watch(
    inspectingEntryDefinitionProvider.select((value) => value?.blueprint),
  );
  if (blueprint == null) return {};
  final queue = <(String, HeaderContext, DataBlueprint)>[
    ("", HeaderContext(), blueprint.dataBlueprint),
  ];
  final result = <String, HeaderActions>{};

  while (queue.isNotEmpty) {
    final (path, context, dataBlueprint) = queue.removeLast();

    final (actions, children) =
        headerActionsFor(ref, path, dataBlueprint, context);
    result[path] = actions;
    queue.addAll(children);
  }

  return result;
}

(HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
    headerActionsFor(
  Ref ref,
  String path,
  DataBlueprint dataBlueprint,
  HeaderContext context,
) =>
        ref
            .watch(editorFiltersProvider)
            .firstWhereOrNull(
              (filter) => filter.canEdit(dataBlueprint),
            )
            ?.headerActions(ref, path, dataBlueprint, context) ??
        (
          const HeaderActions(),
          [],
        );

@freezed
class HeaderContext with _$HeaderContext {
  const factory HeaderContext({
    DataBlueprint? parentBlueprint,
    DataBlueprint? genericBlueprint,
  }) = _HeaderContext;
}

@riverpod
HeaderActions _actions(Ref ref, String path) {
  return ref.watch(headerActionsProvider)[path] ?? const HeaderActions();
}

class FieldHeader extends HookConsumerWidget {
  const FieldHeader({
    required this.child,
    required this.path,
    this.canExpand = false,
    this.defaultExpanded = false,
    super.key,
  }) : super();

  final Widget child;
  final String path;

  final bool canExpand;
  final bool defaultExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    final parent = Header.maybeOf(context);

    // If there already is a header for this path, we don't need to create a new
    if (parent?.path == path) {
      return child;
    }

    final actions = ref.watch(_actionsProvider(path));

    final name =
        ref.watch(pathDisplayNameProvider(path)).nullIfEmpty ?? l10n.fields;

    final expanded = useState(defaultExpanded);
    final depth = (parent?.depth ?? -1) + 1;

    return Header(
      key: ValueKey(path),
      path: path,
      expanded: expanded,
      canExpand: canExpand,
      depth: depth,
      child: Material(
        color: canExpand
            ? depth.isEven
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surfaceContainer
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              borderRadius: BorderRadius.circular(4),
              clipBehavior: Clip.none,
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap:
                    canExpand ? () => expanded.value = !expanded.value : null,
                child: WritersIndicator(
                  enabled: canExpand && !expanded.value,
                  provider: fieldWritersProvider(path),
                  offset:
                      canExpand ? const Offset(50, 25) : const Offset(15, 15),
                  child: Row(
                    children: [
                      if (canExpand)
                        Icon(
                          expanded.value
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ...createActions(
                        actions,
                        HeaderActionLocation.leading,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: canExpand ? 10 : 0,
                        ),
                        child: SectionTitle(
                          title: name,
                        ),
                      ),
                      ...createActions(
                        actions,
                        HeaderActionLocation.trailing,
                      ),
                      const Spacer(),
                      ...createActions(
                        actions,
                        HeaderActionLocation.actions,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (canExpand)
              Collapsible(
                collapsed: !expanded.value,
                axis: CollapsibleAxis.vertical,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: child,
                ),
              )
            else
              child,
          ],
        ),
      ),
    );
  }

  List<Widget> createActions(
    HeaderActions actions,
    HeaderActionLocation location,
  ) {
    final children = switch (location) {
      HeaderActionLocation.leading => actions.leading,
      HeaderActionLocation.trailing => actions.trailing,
      HeaderActionLocation.actions => actions.actions,
    };

    if (children.isEmpty) return children;

    return [
      if (location == HeaderActionLocation.leading ||
          location == HeaderActionLocation.trailing)
        const SizedBox(width: 8),
      ...children.joinWith(() => const SizedBox(width: 8)),
      if (location == HeaderActionLocation.leading) const SizedBox(width: 8),
    ];
  }
}

class Header extends InheritedWidget {
  const Header({
    required this.path,
    required this.expanded,
    required this.canExpand,
    required super.child,
    required this.depth,
    super.key,
  });

  final String path;
  final ValueNotifier<bool> expanded;
  final bool canExpand;
  final int depth;

  @override
  bool updateShouldNotify(covariant Header oldWidget) => path != oldWidget.path;

  static Header? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Header>();
}

class HeaderActions {
  const HeaderActions({
    this.leading = const [],
    this.trailing = const [],
    this.actions = const [],
  });

  final List<Widget> leading;
  final List<Widget> trailing;
  final List<Widget> actions;

  HeaderActions merge(HeaderActions other) {
    return HeaderActions(
      leading: [...leading, ...other.leading],
      trailing: [...trailing, ...other.trailing],
      actions: [...actions, ...other.actions],
    );
  }

  HeaderActions mapWidgets(Widget Function(Widget) mapper) {
    return HeaderActions(
      leading: leading.map(mapper).toList(),
      trailing: trailing.map(mapper).toList(),
      actions: actions.map(mapper).toList(),
    );
  }
}

@riverpod
List<HeaderActionFilter> headerActionFilters(Ref ref) => [
      HelpHeaderActionFilter(),
      ColoredHeaderActionFilter(),
      PlaceholderHeaderActionFilter(),
      RegexHeaderActionFilter(),
      LengthHeaderActionFilter(),
      ContentModeHeaderActionFilter(),
      VariableHeaderActionFilter(),

      BooleanHeaderActionFilter(),
      ClosedRangeHeaderActionFilter(),

      // List Actions
      AddListHeaderActionFilter(),
      ReorderListHeaderActionFilter(),
      DuplicateListItemActionFilter(),
      RemoveListItemActionFilter(),

      // Map Actions
      AddMapHeaderActionFilter(),

      // Skin Actions
      SkinFetchFromUUIDHeaderActionFilter(),
      SkinFetchFromURLHeaderActionFilter(),
    ];

abstract class HeaderActionFilter {
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  );

  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  );

  Widget build(String path, HeaderContext context, DataBlueprint dataBlueprint);
}

enum HeaderActionLocation {
  leading,
  trailing,
  actions,
}
