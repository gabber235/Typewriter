import "package:collapsible/collapsible.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "header.freezed.dart";
part "header.g.dart";

@riverpod
Map<String, HeaderActions> currentHeaderActions(
  Ref ref,
  EditorMode editorMode,
) {
  final blueprint = ref.watch(selectedDataBlueprintProvider);
  if (blueprint == null) return {};
  final queue = <(String, HeaderContext, DataBlueprint)>[
    ("", HeaderContext(), blueprint),
  ];
  final result = <String, HeaderActions>{};

  while (queue.isNotEmpty) {
    final (path, context, dataBlueprint) = queue.removeLast();

    final (actions, children) = headerActionsFor(
      ref,
      path,
      dataBlueprint,
      context,
      editorMode,
    );
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
        .firstWhereOrNull((filter) => filter.canEdit(dataBlueprint))
        ?.headerActions(ref, path, dataBlueprint, context, editorMode) ??
    (const HeaderActions(), []);

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
    required this.dataBlueprint,
    required this.editorMode,
    this.title,
    this.canExpand = false,
    this.defaultExpanded,
    super.key,
  });

  final Widget child;
  final String path;
  final DataBlueprint dataBlueprint;
  final EditorMode editorMode;

  final String? title;

  final bool canExpand;
  final bool? defaultExpanded;

  bool get _defaultExpanded =>
      (defaultExpanded ?? !editorMode.hasHeaderActions) ||
      dataBlueprint.hasModifier<ExpandedModifier>();

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
        title ??
        ref.watch(pathDisplayNameProvider(path)).nullIfEmpty ??
        "Editor";

    final expanded = useState(_defaultExpanded);

    return Header(
      key: ValueKey(path),
      path: path,
      expanded: expanded,
      canExpand: canExpand,
      child: DepthBox(
        enabled: canExpand,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              borderRadius: context.shapes.smallBorderRadius,
              clipBehavior: Clip.none,
              color: Colors.transparent,
              child: InkWell(
                borderRadius: context.shapes.smallBorderRadius,
                onTap: canExpand
                    ? () => expanded.value = !expanded.value
                    : null,
                child: Row(
                  children: [
                    if (canExpand && editorMode.hasHeaderActions)
                      Icon(
                        expanded.value ? Icons.expand_less : Icons.expand_more,
                      )
                    else if (canExpand)
                      SizedBox(width: context.spacing.space2),
                    if (editorMode.hasHeaderActions)
                      ...createActions(actions, HeaderActionLocation.leading),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: canExpand ? 10 : 0,
                      ),
                      child: SectionTitle(title: name),
                    ),
                    if (editorMode.hasHeaderActions)
                      ...createActions(actions, HeaderActionLocation.trailing),
                    const Spacer(),
                    if (editorMode.hasHeaderActions)
                      ...createActions(actions, HeaderActionLocation.actions),
                  ],
                ),
              ),
            ),
            if (canExpand)
              // TODO: look into replacing this with native Expansible widget
              Collapsible(
                collapsed: !expanded.value,
                axis: CollapsibleAxis.vertical,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
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
    super.key,
  });

  final String path;
  final ValueNotifier<bool> expanded;
  final bool canExpand;

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

enum HeaderActionLocation { leading, trailing, actions }
