part of "../../layout_renderer.dart";

extension TabsElementRendering on TabsElement {
  Widget render(PresentationRenderScope scope) =>
      _TabsRenderer(element: this, scope: scope);
}

class _TabsRenderer extends StatefulWidget {
  const _TabsRenderer({required this.element, required this.scope});

  final TabsElement element;
  final PresentationRenderScope scope;

  @override
  State<_TabsRenderer> createState() => _TabsRendererState();
}

class _TabsRendererState extends State<_TabsRenderer>
    with SingleTickerProviderStateMixin {
  late String _selected;
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _selected = _initialSelection();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(_TabsRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.element.tabs.any((tab) => tab.id == _selected)) {
      _selected = _initialSelection();
    }
    final selectedIndex = _selectedIndex;
    if (!_hasSameTabOrder(oldWidget.element.tabs)) {
      _controller
        ..removeListener(_syncSelection)
        ..dispose();
      _controller = _createController();
    } else if (_controller.index != selectedIndex) {
      _controller.index = selectedIndex;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncSelection)
      ..dispose();
    super.dispose();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveChoiceControl<String>(
          selected: _selected,
          choices: {
            for (final tab in widget.element.tabs)
              tab.id: widget.scope.expressionText(tab.label),
          },
          onSelected: _select,
        ),
        SizedBox(height: context.spacing.space3),
        ContentSizeTabBarView(
          key: ObjectKey(_controller),
          controller: _controller,
          children: [
            for (final tab in widget.element.tabs)
              PresentationNodeRenderer(node: tab.child, scope: widget.scope),
          ],
        ),
      ],
    );
  }

  void _select(String? selection) {
    if (selection == null || selection == _selected) return;
    final index = widget.element.tabs.indexWhere((tab) => tab.id == selection);
    if (index < 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.index = index;
      return;
    }
    _controller.animateTo(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  int get _selectedIndex =>
      widget.element.tabs.indexWhere((tab) => tab.id == _selected);

  TabController _createController() => TabController(
    length: widget.element.tabs.length,
    initialIndex: _selectedIndex,
    vsync: this,
  )..addListener(_syncSelection);

  void _syncSelection() {
    final selected = widget.element.tabs[_controller.index].id;
    if (selected == _selected) return;
    setState(() => _selected = selected);
  }

  bool _hasSameTabOrder(List<TabItem> previous) {
    final current = widget.element.tabs;
    if (previous.length != current.length) return false;
    for (var index = 0; index < current.length; index++) {
      if (previous[index].id != current[index].id) return false;
    }
    return true;
  }
}
