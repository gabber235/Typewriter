import "package:typewriter_panel/typewriter_panel.dart";

/// Displays the visible registered actions for desktop sized surfaces.
///
/// Actions are ordered by priority and laid out from the right. If the row is
/// too narrow, lower priority actions are omitted while the highest priority
/// suffix remains visible. The row is empty on mobile breakpoints.
class ActionRow extends HookConsumerWidget {
  const ActionRow({this.spacing = 0, super.key});

  final double spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsMap = ref.watch(actionShortcutsProvider);
    if (context.isMobile || actionsMap.isEmpty) {
      return const SizedBox.shrink();
    }

    final actions = useMemoized(() {
      final filtered =
          actionsMap.values
              .where((a) => a.owner == null || a.owner!.currentContext != null)
              .where((a) => a.show)
              .toList()
            ..sort((a, b) => a.priority.compareTo(b.priority));
      return filtered;
    }, [actionsMap]);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space4),
      child: _ActionRowLayout(
        spacing: spacing,
        children: [
          for (final action in actions)
            _ActionShortcutButton(key: ValueKey(action.id), action: action),
        ],
      ),
    );
  }
}

class _ActionRowParentData extends ContainerBoxParentData<RenderBox> {
  bool isVisible = false;
}

class _ActionRowLayout extends MultiChildRenderObjectWidget {
  const _ActionRowLayout({required this.spacing, super.children});

  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderActionRowLayout(spacing: spacing);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderActionRowLayout renderObject,
  ) {
    renderObject.spacing = spacing;
  }
}

class _RenderActionRowLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionRowParentData> {
  _RenderActionRowLayout({required this._spacing});

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _ActionRowParentData) {
      child.parentData = _ActionRowParentData();
    }
  }

  @override
  void performLayout() {
    final childConstraints = BoxConstraints();

    final childSizes = <RenderBox, Size>{};
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      childSizes[child] = child.size;
      children.add(child);
      child = childAfter(child);
    }

    final maxWidth = constraints.maxWidth;

    var visibleCount = 0;
    var totalWidth = 0.0;
    for (var i = children.length - 1; i >= 0; i--) {
      final childSize = childSizes[children[i]]!;
      final additionalWidth =
          childSize.width + (visibleCount > 0 ? spacing : 0);
      if (totalWidth + additionalWidth > maxWidth) break;
      totalWidth += additionalWidth;
      visibleCount++;
    }

    final startIndex = children.length - visibleCount;
    var maxHeight = 0.0;

    for (var i = 0; i < children.length; i++) {
      final c = children[i];
      final parentData = c.parentData! as _ActionRowParentData
        ..isVisible = i >= startIndex;
      if (parentData.isVisible) {
        final childSize = childSizes[c]!;
        if (childSize.height > maxHeight) {
          maxHeight = childSize.height;
        }
      }
    }

    var xOffset = maxWidth - totalWidth;
    for (var i = startIndex; i < children.length; i++) {
      final c = children[i];
      final parentData = c.parentData! as _ActionRowParentData;
      final childSize = childSizes[c]!;
      final yOffset = (maxHeight - childSize.height) / 2;
      parentData.offset = Offset(xOffset, yOffset);
      xOffset += childSize.width + spacing;
    }

    size = constraints.constrain(Size(maxWidth, maxHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _ActionRowParentData;
      if (parentData.isVisible) {
        context.paintChild(child, parentData.offset + offset);
      }
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as _ActionRowParentData;
      if (parentData.isVisible) {
        final isHit = result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (result, transformed) {
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty("spacing", spacing));
  }
}

class _ActionShortcutButton extends HookConsumerWidget {
  const _ActionShortcutButton({required this.action, super.key});

  final ActionShortcut action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = useState(false);
    final hasInvoke = action.canInvoke && !loading.value;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: context.spacing.space2,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (loading.value)
          const SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (action.icon != null)
          action.icon!,
        Flexible(child: Text(action.label, overflow: TextOverflow.ellipsis)),
        RotatingShortcuts(
          shortcuts: action.shortcuts,
          size: 9,
          interval: 5.seconds,
        ),
      ],
    );

    final pill = AnimatedOpacity(
      duration: 150.ms,
      opacity: loading.value ? 0.7 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
          ),
          child: IconTheme(
            data: IconThemeData(
              size: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (!hasInvoke) {
      return Tooltip(message: action.description, child: pill);
    }

    return Material(
      shape: const StadiumBorder(),
      child: Tooltip(
        message: action.description,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () async {
            if (loading.value) return;
            loading.value = true;
            try {
              await action.onInvoke!(ref);
            } finally {
              if (context.mounted) {
                loading.value = false;
              }
            }
          },
          child: pill,
        ),
      ),
    );
  }
}
