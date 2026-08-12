import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension LayoutElementRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    return switch (element) {
      ColumnElement() => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: element.mainAxisAlignment._mainAxis,
        crossAxisAlignment: element.crossAxisAlignment._crossAxis,
        children: element.children._spaced(
          element.spacing,
          scope,
          vertical: true,
        ),
      ),
      RowElement() => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: element.mainAxisAlignment._mainAxis,
        crossAxisAlignment: element.crossAxisAlignment._crossAxis,
        children: element.children._spaced(element.spacing, scope),
      ),
      WrapElement() => Wrap(
        spacing: element.spacing,
        runSpacing: element.spacing,
        alignment: element.mainAxisAlignment._wrapAlignment,
        crossAxisAlignment: element.crossAxisAlignment._wrapCrossAlignment,
        children: element.children._render(scope),
      ),
      StackElement() => Stack(children: element.children._render(scope)),
      GridElement() => _Grid(element: element, scope: scope),
      ScrollElement(:final child) => SingleChildScrollView(
        child: PresentationNodeRenderer(node: child, scope: scope),
      ),
      CardElement() => _Card(element: element, scope: scope),
      SectionElement() => _Section(element: element, scope: scope),
      CollapsibleElement() => _Collapsible(element: element, scope: scope),
      TabsElement() => _Tabs(element: element, scope: scope),
      DividerElement() => const Divider(height: 24),
      SpacerElement(:final width, :final height) => SizedBox(
        width: width._size(scope),
        height: height._size(scope),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

extension on TypedExpression? {
  double? _size(PresentationRenderScope scope) {
    if (this == null) return null;
    final value = scope.evaluate(this!).valueOrNull;
    final size = switch (value) {
      IntegerValue(:final value) => value.toDouble(),
      FloatValue(:final value) => value,
      DecimalValue(:final value) => double.tryParse(value),
      _ => null,
    };
    return size == null || size < 0 ? null : size;
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.element, required this.scope});

  final CardElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final child = PresentationNodeRenderer(node: element.child, scope: scope);
    final content = element.initiallyExpanded == null
        ? child
        : ExpansionTile(
            initiallyExpanded: element.initiallyExpanded!,
            title: const SizedBox.shrink(),
            children: [child],
          );
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}

class _Collapsible extends StatelessWidget {
  const _Collapsible({required this.element, required this.scope});

  final CollapsibleElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: element.initiallyExpanded,
    title: Text(scope.expressionText(element.title)),
    children: [PresentationNodeRenderer(node: element.child, scope: scope)],
  );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.element, required this.scope});

  final GridElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final gaps = element.horizontalSpacing * (element.columns - 1);
      final width = (constraints.maxWidth - gaps) / element.columns;
      return Wrap(
        spacing: element.horizontalSpacing,
        runSpacing: element.verticalSpacing,
        children: [
          for (final child in element.children)
            SizedBox(
              width: width,
              child: PresentationNodeRenderer(node: child, scope: scope),
            ),
        ],
      );
    },
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.element, required this.scope});

  final SectionElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final title = scope.expressionText(element.title);
    final description = element.description == null
        ? null
        : scope.expressionText(element.description!);
    final child = PresentationNodeRenderer(node: element.child, scope: scope);
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledMessage(label: title, message: description),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
    if (element.initiallyExpanded == null) return Section(child: content);
    return Section(
      child: ExpansionTile(
        initiallyExpanded: element.initiallyExpanded!,
        title: LabeledMessage(label: title, message: description),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }
}

class _Tabs extends StatefulWidget {
  const _Tabs({required this.element, required this.scope});

  final TabsElement element;
  final PresentationRenderScope scope;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = _initialSelection();
  }

  @override
  void didUpdateWidget(_Tabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.element.tabs.any((tab) => tab.id == _selected)) {
      _selected = _initialSelection();
    }
  }

  String _initialSelection() {
    final requested = widget.element.initiallySelectedTabId;
    if (requested != null &&
        widget.element.tabs.any((tab) => tab.id == requested)) {
      return requested;
    }
    return widget.element.tabs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = widget.element.tabs.firstWhere(
      (tab) => tab.id == _selected,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: [
            for (final tab in widget.element.tabs)
              ButtonSegment(
                value: tab.id,
                label: Text(widget.scope.expressionText(tab.label)),
              ),
          ],
          selected: {_selected},
          onSelectionChanged: (selection) {
            setState(() => _selected = selection.single);
          },
        ),
        const SizedBox(height: 12),
        PresentationNodeRenderer(node: selectedTab.child, scope: widget.scope),
      ],
    );
  }
}

extension on List<PresentationNode> {
  List<Widget> _render(PresentationRenderScope scope) => [
    for (final child in this)
      PresentationNodeRenderer(node: child, scope: scope),
  ];

  List<Widget> _spaced(
    double spacing,
    PresentationRenderScope scope, {
    bool vertical = false,
  }) => [
    for (final entry in indexed) ...[
      if (entry.$1 > 0)
        SizedBox(width: vertical ? 0 : spacing, height: vertical ? spacing : 0),
      PresentationNodeRenderer(node: entry.$2, scope: scope),
    ],
  ];
}

extension on PresentationMainAxisAlignment {
  MainAxisAlignment get _mainAxis => switch (this) {
    PresentationMainAxisAlignment.start => MainAxisAlignment.start,
    PresentationMainAxisAlignment.center => MainAxisAlignment.center,
    PresentationMainAxisAlignment.end => MainAxisAlignment.end,
    PresentationMainAxisAlignment.spaceBetween =>
      MainAxisAlignment.spaceBetween,
    PresentationMainAxisAlignment.spaceAround => MainAxisAlignment.spaceAround,
    PresentationMainAxisAlignment.spaceEvenly => MainAxisAlignment.spaceEvenly,
  };

  WrapAlignment get _wrapAlignment => WrapAlignment.values[_mainAxis.index];
}

extension on PresentationCrossAxisAlignment {
  CrossAxisAlignment get _crossAxis => switch (this) {
    PresentationCrossAxisAlignment.start => CrossAxisAlignment.start,
    PresentationCrossAxisAlignment.center => CrossAxisAlignment.center,
    PresentationCrossAxisAlignment.end => CrossAxisAlignment.end,
    PresentationCrossAxisAlignment.stretch => CrossAxisAlignment.stretch,
  };

  WrapCrossAlignment get _wrapCrossAlignment => switch (this) {
    PresentationCrossAxisAlignment.start => WrapCrossAlignment.start,
    PresentationCrossAxisAlignment.center => WrapCrossAlignment.center,
    PresentationCrossAxisAlignment.end ||
    PresentationCrossAxisAlignment.stretch => WrapCrossAlignment.end,
  };
}
