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

class _TabsRendererState extends State<_TabsRenderer> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = _initialSelection();
  }

  @override
  void didUpdateWidget(_TabsRenderer oldWidget) {
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
        AdaptiveChoiceControl<String>(
          selected: _selected,
          choices: {
            for (final tab in widget.element.tabs)
              tab.id: widget.scope.expressionText(tab.label),
          },
          onSelected: _select,
        ),
        const SizedBox(height: 12),
        PresentationNodeRenderer(node: selectedTab.child, scope: widget.scope),
      ],
    );
  }

  void _select(String? selection) {
    if (selection == null || selection == _selected) return;
    setState(() => _selected = selection);
  }
}
