import "package:collapsible/collapsible.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/boolean_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/headers/list_header.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";

part "header.freezed.dart";
part "header.g.dart";

@riverpod
Map<String, HeaderActions> currentHeaderActions(
  Ref ref,
  EditorMode editorMode,
) {
  final blueprint = ref.watch(
    selectedDataBlueprintProvider,
  );
  if (blueprint == null) return {};
  final queue = <(String, HeaderContext, DataBlueprint)>[
    ("", HeaderContext(), blueprint),
  ];
  final result = <String, HeaderActions>{};

  while (queue.isNotEmpty) {
    final (path, context, dataBlueprint) = queue.removeLast();

    final (actions, children) =
        headerActionsFor(ref, path, dataBlueprint, context, editorMode);
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
  EditorMode editorMode,
) =>
        ref
            .watch(editorsProvider)
            .firstWhereOrNull(
              (filter) => filter.canEdit(dataBlueprint),
            )
            ?.headerActions(ref, path, dataBlueprint, context, editorMode) ??
        (
          const HeaderActions(),
          [],
        );

@freezed
sealed class HeaderContext with _$HeaderContext {
  const factory HeaderContext({
    DataBlueprint? parentBlueprint,
    DataBlueprint? genericBlueprint,
  }) = _HeaderContext;
}

@riverpod
HeaderActions _actions(Ref ref, String path, EditorMode editorMode) {
  return ref.watch(currentHeaderActionsProvider(editorMode))[path] ??
      const HeaderActions();
}

class FieldHeader extends HookConsumerWidget {
  const FieldHeader({
    required this.child,
    required this.path,
    required this.editorMode,
    this.canExpand = false,
    this.defaultExpanded,
    super.key,
  });

  final Widget child;
  final String path;
  final EditorMode editorMode;

  final bool canExpand;
  final bool? defaultExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = Header.maybeOf(context);

    // If there already is a header for this path, we don't need to create a new
    if (parent?.path == path) {
      return child;
    }

    final actions = editorMode.hasHeaderActions
        ? ref.watch(_actionsProvider(path, editorMode))
        : HeaderActions();

    final name =
        ref.watch(pathDisplayNameProvider(path)).nullIfEmpty ?? "Editor";

    final expanded = useState(defaultExpanded ?? !editorMode.hasHeaderActions);
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
                ? Theme.of(context).colorScheme.surfaceContainerLowest
                : Theme.of(context).colorScheme.surface
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
                child: Row(
                  children: [
                    if (canExpand && editorMode.hasHeaderActions)
                      Icon(
                        expanded.value ? Icons.expand_less : Icons.expand_more,
                      )
                    else if (canExpand)
                      const SizedBox(width: 8),
                    if (editorMode.hasHeaderActions)
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
                    if (editorMode.hasHeaderActions)
                      ...createActions(
                        actions,
                        HeaderActionLocation.trailing,
                      ),
                    const Spacer(),
                    if (editorMode.hasHeaderActions)
                      ...createActions(
                        actions,
                        HeaderActionLocation.actions,
                      ),
                  ],
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
List<HeaderAction> headerActions(Ref ref) => [
      // HelpHeaderActionFilter(),
      // ColoredHeaderActionFilter(),
      // PlaceholderHeaderActionFilter(),
      // RegexHeaderActionFilter(),
      // LengthHeaderActionFilter(),
      // ContentModeHeaderActionFilter(),
      // VariableHeaderActionFilter(),
      //
      BooleanHeaderAction(),
      // ClosedRangeHeaderActionFilter(),
      //
      // // List Actions
      AddListHeaderAction(),
      ReorderListHeaderAction(),
      DuplicateListItemAction(),
      RemoveListItemAction(),
      //
      // // Map Actions
      // AddMapHeaderActionFilter(),
      //
      // // Skin Actions
      // SkinFetchFromUUIDHeaderActionFilter(),
      // SkinFetchFromURLHeaderActionFilter(),
    ];

abstract class HeaderAction {
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  );

  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  );

  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  );
}

enum HeaderActionLocation {
  leading,
  trailing,
  actions,
}
