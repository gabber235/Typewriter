part of "../portable_presentation_renderer.dart";

final class _AuthoredReorderTarget {
  const _AuthoredReorderTarget({
    required this.containing,
    required this.item,
    required this.items,
    required this.index,
  });

  final skir.ValueLocation containing;
  final skir.ItemId item;
  final List<skir.ListItem> items;
  final int index;
}

final class _MoveEarlierIntent extends Intent {
  const _MoveEarlierIntent();
}

final class _MoveLaterIntent extends Intent {
  const _MoveLaterIntent();
}

final class _AuthoredReorderHandle extends StatefulWidget {
  const _AuthoredReorderHandle({
    required this.index,
    required this.label,
    required this.enabled,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onMoveEarlier,
    required this.onMoveLater,
  });

  final int index;
  final String label;
  final bool enabled;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;

  @override
  State<_AuthoredReorderHandle> createState() => _AuthoredReorderHandleState();
}

final class _AuthoredReorderHandleState extends State<_AuthoredReorderHandle> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    focusNode: _focusNode,
    enabled: widget.enabled,
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
          _MoveEarlierIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
          _MoveLaterIntent(),
    },
    actions: {
      _MoveEarlierIntent: CallbackAction<_MoveEarlierIntent>(
        onInvoke: (_) {
          if (widget.canMoveEarlier) widget.onMoveEarlier();
          return null;
        },
      ),
      _MoveLaterIntent: CallbackAction<_MoveLaterIntent>(
        onInvoke: (_) {
          if (widget.canMoveLater) widget.onMoveLater();
          return null;
        },
      ),
    },
    onShowFocusHighlight: (focused) => setState(() => _focused = focused),
    child: Tooltip(
      message: widget.label,
      child: ReorderableDragStartListener(
        index: widget.index,
        enabled: widget.enabled,
        child: GestureDetector(
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: _focused
                    ? Theme.of(context).colorScheme.primary
                    : context.colors.surface.withValues(alpha: 0),
                width: 2,
              ),
              borderRadius: context.shapes.smallBorderRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.drag_handle,
                color: widget.enabled ? null : Theme.of(context).disabledColor,
                semanticLabel: widget.label,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
