import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "header_action_resolution.dart";
part "header_renderer.freezed.dart";

class PresentationHeaderChrome extends StatefulWidget {
  const PresentationHeaderChrome({
    required this.nodeId,
    required this.header,
    required this.scope,
    required this.child,
    super.key,
  });

  final String nodeId;
  final PresentationHeader header;
  final PresentationRenderScope scope;
  final Widget child;

  @override
  State<PresentationHeaderChrome> createState() =>
      _PresentationHeaderChromeState();
}

class _PresentationHeaderChromeState extends State<PresentationHeaderChrome> {
  late ExpansibleController _expansibleController;

  BindingReference? get _binding => widget.header.binding == null
      ? null
      : widget.scope.canonical(widget.header.binding!);

  @override
  void initState() {
    super.initState();
    _expansibleController = _createExpansibleController();
  }

  @override
  void didUpdateWidget(PresentationHeaderChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bindingChanged = oldWidget.header.binding == null
        ? widget.header.binding != null
        : widget.header.binding == null ||
              oldWidget.scope.canonical(oldWidget.header.binding!) != _binding;
    if (oldWidget.nodeId != widget.nodeId ||
        bindingChanged ||
        oldWidget.header.initiallyExpanded != widget.header.initiallyExpanded) {
      _expansibleController.dispose();
      _expansibleController = _createExpansibleController();
    }
  }

  @override
  void dispose() {
    _expansibleController.dispose();
    super.dispose();
  }

  bool _storedExpansion() => widget.scope.expansionStore.value(
    nodeId: widget.nodeId,
    binding: _binding,
    initial: widget.header.initiallyExpanded ?? true,
  );

  ExpansibleController _createExpansibleController() {
    final controller = ExpansibleController();
    if (_storedExpansion()) controller.expand();
    return controller;
  }

  void _toggle() {
    if (widget.header.initiallyExpanded == null) return;
    _expansibleController.toggle();
    widget.scope.expansionStore.set(
      nodeId: widget.nodeId,
      binding: _binding,
      expanded: _expansibleController.isExpanded,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.header.title == null
        ? ""
        : widget.scope.expressionText(widget.header.title!);
    final description = widget.header.description == null
        ? ""
        : widget.scope.expressionText(widget.header.description!);
    final items = [
      for (final (index, item) in widget.header.items.indexed)
        item.resolve(widget.scope, index),
    ].where((item) => item.visible).toList();
    final shortcuts = [
      for (final item in items) ...item.shortcuts(context, widget.scope),
    ];
    final headerRow = _HeaderRow(
      title: title,
      items: items,
      scope: widget.scope,
      collapsible: widget.header.initiallyExpanded != null,
      expanded: _expansibleController.isExpanded,
    );
    final collapsible = widget.header.initiallyExpanded != null;
    final headerContent = Material(
      color: Colors.transparent,
      borderRadius: context.shapes.smallBorderRadius,
      child: InkWell(
        onTap: collapsible ? _toggle : null,
        borderRadius: context.shapes.smallBorderRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: collapsible ? context.spacing.space1 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: context.spacing.space1,
            children: [
              headerRow,
              if (description.isNotEmpty) ...[
                SizedBox(
                  key: ValueKey((
                    "presentationHeaderDescription",
                    widget.nodeId,
                  )),
                  width: double.infinity,
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.contentSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final content = collapsible
        ? Expansible(
            controller: _expansibleController,
            animationStyle: const AnimationStyle(
              duration: Duration(milliseconds: 240),
              curve: Curves.easeOut,
            ),
            maintainState: false,
            headerBuilder: (context, animation) => headerContent,
            bodyBuilder: (context, animation) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space1,
              ),
              child: widget.child,
            ),
            expansibleBuilder: (context, header, body, animation) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, body],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [headerContent, widget.child],
          );
    return ManagedActionSet(
      shortcuts: shortcuts,
      child: DepthBox(enabled: collapsible, child: content),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.items,
    required this.scope,
    required this.collapsible,
    required this.expanded,
  });

  final String title;
  final List<_ResolvedHeaderItem> items;
  final PresentationRenderScope scope;
  final bool collapsible;
  final bool expanded;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final reorderHandles = items
          .whereType<_ResolvedHeaderReorderHandleItem>();
      final beforeTitle = items.at(HeaderActionPlacement.beforeTitle);
      final afterTitle = items.at(HeaderActionPlacement.afterTitle);
      final end = items.at(HeaderActionPlacement.end);
      final fixedWidth =
          180 +
          (reorderHandles.length + beforeTitle.length + afterTitle.length) * 40;
      final availableItems = ((constraints.maxWidth - fixedWidth) / 40)
          .floor()
          .clamp(0, end.length);
      final visible = end.take(availableItems).toList();
      final overflow = end.skip(availableItems).toList();
      return Row(
        children: [
          if (collapsible)
            SizedBox.square(
              dimension: 40,
              child: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
            ),
          for (final item in reorderHandles) item.inlineWidget(context, scope),
          for (final item in beforeTitle) item.inlineWidget(context, scope),
          Flexible(child: SectionTitle(title: title)),
          for (final item in afterTitle) item.inlineWidget(context, scope),
          const Spacer(),
          for (final item in visible) item.inlineWidget(context, scope),
          if (overflow.isNotEmpty)
            _OverflowItems(items: overflow, scope: scope),
        ],
      );
    },
  );
}

extension on List<_ResolvedHeaderItem> {
  List<_ResolvedHeaderItem> at(HeaderActionPlacement placement) =>
      [
        for (final item in this)
          if (item.placement == placement) item,
      ]..sort((left, right) {
        final priority = right.priority.compareTo(left.priority);
        return priority != 0
            ? priority
            : left.declarationOrder.compareTo(right.declarationOrder);
      });
}

class _OverflowItems extends StatelessWidget {
  const _OverflowItems({required this.items, required this.scope});

  final List<_ResolvedHeaderItem> items;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) => ContextMenuRegion(
    enableGestures: false,
    items: [for (final item in items) item.overflowItem(context, scope)],
    builder: (context, controller, child) => IconButton(
      tooltip: "More actions",
      onPressed: ContextMenuRegion.onPress(controller),
      icon: const Icones(Fa6Solid.ellipsis),
    ),
  );
}
