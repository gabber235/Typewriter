import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "header_action_resolution.dart";
part "header_renderer.freezed.dart";

class PresentationHeaderChrome extends StatelessWidget {
  const PresentationHeaderChrome({
    required this.nodeId,
    required this.header,
    required this.scope,
    required this.child,
    this.leading,
    super.key,
  });

  final String nodeId;
  final PresentationHeader header;
  final PresentationRenderScope scope;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final binding = header.binding == null
        ? null
        : scope.canonical(header.binding!);
    final title = header.title == null
        ? ""
        : scope.expressionText(header.title!);
    final description = header.description == null
        ? ""
        : scope.expressionText(header.description!);
    final actions = [
      for (final (index, action) in header.actions.indexed)
        action._resolve(scope, index),
    ].where((action) => action.visible).toList();
    final shortcuts = [
      for (final action in actions)
        action._shortcut(
          context,
          scope.headerShortcuts[action.id] ?? const [],
          scope,
        ),
    ];
    final headerRow = _HeaderRow(
      title: title,
      description: description,
      actions: actions,
      scope: scope,
      leading: leading,
    );
    final collapsible = header.initiallyExpanded;
    final content = collapsible == null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [headerRow, child],
          )
        : ExpansionTile(
            key: ValueKey(("presentationHeader", nodeId, binding)),
            initiallyExpanded: scope.expansionStore.value(
              nodeId: nodeId,
              binding: binding,
              initial: collapsible,
            ),
            onExpansionChanged: (expanded) => scope.expansionStore.set(
              nodeId: nodeId,
              binding: binding,
              expanded: expanded,
            ),
            maintainState: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: headerRow,
            children: [child],
          );
    return ManagedActionSet(shortcuts: shortcuts, child: content);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.description,
    required this.actions,
    required this.scope,
    this.leading,
  });

  final String title;
  final String description;
  final List<_ResolvedHeaderAction> actions;
  final PresentationRenderScope scope;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final beforeTitle = actions.at(HeaderActionPlacement.beforeTitle);
      final afterTitle = actions.at(HeaderActionPlacement.afterTitle);
      final end = actions.at(HeaderActionPlacement.end);
      final fixedWidth = 180 + (beforeTitle.length + afterTitle.length) * 40;
      final availableActions = ((constraints.maxWidth - fixedWidth) / 40)
          .floor()
          .clamp(0, end.length);
      final visible = end.take(availableActions).toList();
      final overflow = end.skip(availableActions).toList();
      return Row(
        children: [
          ?leading,
          for (final action in beforeTitle) action._button(context, scope),
          Flexible(
            child: LabeledMessage(label: title, message: description),
          ),
          for (final action in afterTitle) action._button(context, scope),
          const Spacer(),
          for (final action in visible) action._button(context, scope),
          if (overflow.isNotEmpty)
            _OverflowActions(actions: overflow, scope: scope),
        ],
      );
    },
  );
}

extension on List<_ResolvedHeaderAction> {
  List<_ResolvedHeaderAction> at(HeaderActionPlacement placement) =>
      [
        for (final action in this)
          if (action.immediate && action.placement == placement) action,
      ]..sort((left, right) {
        final priority = right.priority.compareTo(left.priority);
        return priority != 0
            ? priority
            : left.declarationOrder.compareTo(right.declarationOrder);
      });
}

class _OverflowActions extends StatelessWidget {
  const _OverflowActions({required this.actions, required this.scope});

  final List<_ResolvedHeaderAction> actions;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) => ContextMenuRegion(
    enableGestures: false,
    items: [
      for (final action in actions)
        MenuItem(
          label: action.label,
          icon: Icones.value(action.icon, size: 18),
          color: action.tone == HeaderActionTone.destructive
              ? Theme.of(context).colorScheme.error
              : null,
          shortcuts: scope.headerShortcuts[action.id] ?? const [],
          onPressed: action.enabled
              ? () => action._invoke(context, scope)
              : null,
        ),
    ],
    builder: (context, controller, child) => IconButton(
      tooltip: "More actions",
      onPressed: ContextMenuRegion.onPress(controller),
      icon: const Icones("mdi:dots-horizontal"),
    ),
  );
}
