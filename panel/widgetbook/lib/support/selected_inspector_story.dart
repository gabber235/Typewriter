import "package:typewriter_panel/typewriter_panel.dart";

/// Seeds a Widgetbook scenario through the public selection API.
class SelectedInspectorStory extends ConsumerStatefulWidget {
  const SelectedInspectorStory({
    required this.selection,
    required this.child,
    super.key,
  });

  final List<SelectableIdentifier> selection;
  final Widget child;

  @override
  ConsumerState<SelectedInspectorStory> createState() =>
      _SelectedInspectorStoryState();
}

class _SelectedInspectorStoryState
    extends ConsumerState<SelectedInspectorStory> {
  late final Selection _selection = ref.read(selectionProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selection.selectAll(widget.selection);
    });
  }

  @override
  void didUpdateWidget(SelectedInspectorStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.selection, widget.selection)) return;
    _selection.selectAll(widget.selection);
  }

  @override
  void dispose() {
    _selection.unselectAll(widget.selection);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
