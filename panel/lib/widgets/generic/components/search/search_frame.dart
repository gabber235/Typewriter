import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/generic/components/draggable_sheet_handle.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

const _maxSearchFrameWidth = 880.0;
const _maxSearchFrameHeightFraction = 0.8;
const _maxPreviewWidth = 320.0;
const _spacing = 12.0;
const _sheetPeekSize = 0.15;
const _sheetMaxSize = 0.9;

_PreviewPlacement _previewPlacement(double width) {
  if (width < _maxSearchFrameWidth) {
    return _PreviewPlacement.sheet;
  }

  final breakpoint =
      width / 2 + _maxSearchFrameWidth / 2 + _spacing + _maxPreviewWidth + 1;
  if (width < breakpoint) {
    return _PreviewPlacement.inline;
  }

  return _PreviewPlacement.external;
}

class SearchFrame extends StatelessWidget {
  const SearchFrame({
    required this.queryBar,
    required this.searchResults,
    this.preview,
    this.actionBar,
    super.key,
  });

  final Widget queryBar;
  final Widget searchResults;
  final Widget? preview;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final placement = _previewPlacement(width);

        return _ResponsiveSearchFrame(
          placement: placement,
          queryBar: queryBar,
          searchResults: searchResults,
          preview: preview,
          actionBar: actionBar,
        );
      },
    );
  }
}

enum _PreviewPlacement { external, inline, sheet }

class _ResponsiveSearchFrame extends StatelessWidget {
  const _ResponsiveSearchFrame({
    required this.placement,
    required this.queryBar,
    required this.searchResults,
    required this.preview,
    required this.actionBar,
  });

  final _PreviewPlacement placement;
  final Widget queryBar;
  final Widget searchResults;
  final Widget? preview;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    return switch (placement) {
      _PreviewPlacement.external => _ExternalPreviewLayout(
        queryBar: queryBar,
        searchResults: searchResults,
        preview: preview,
        actionBar: actionBar,
      ),
      _PreviewPlacement.inline => _LimitHeight(
        child: _PrimarySearchFrame(
          queryBar: queryBar,
          searchResults: searchResults,
          preview: preview,
          actionBar: actionBar,
        ),
      ),
      _PreviewPlacement.sheet => _SheetPreviewLayout(
        queryBar: queryBar,
        searchResults: searchResults,
        preview: preview,
      ),
    };
  }
}

class _LimitHeight extends StatelessWidget {
  const _LimitHeight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final limit = height * _maxSearchFrameHeightFraction;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: limit),
          child: child,
        );
      },
    );
  }
}

class _ExternalPreviewLayout extends HookWidget {
  const _ExternalPreviewLayout({
    required this.queryBar,
    required this.searchResults,
    required this.preview,
    required this.actionBar,
  });

  final Widget queryBar;
  final Widget searchResults;
  final Widget? preview;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    late final link = useRef(LayerLink());
    return Stack(
      children: [
        Center(
          child: CompositedTransformTarget(
            link: link.value,
            child: _LimitHeight(
              child: _PrimarySearchFrame(
                queryBar: queryBar,
                searchResults: searchResults,
                actionBar: actionBar,
              ),
            ),
          ),
        ),
        CompositedTransformFollower(
          link: link.value,
          offset: Offset(_spacing, 0),
          showWhenUnlinked: false,
          targetAnchor: Alignment.centerRight,
          followerAnchor: Alignment.centerLeft,
          child: _LimitHeight(child: _ExternalPreviewSlot(preview: preview)),
        ),
      ],
    );
  }
}

class _SheetPreviewLayout extends HookWidget {
  const _SheetPreviewLayout({
    required this.queryBar,
    required this.searchResults,
    required this.preview,
  });

  final Widget queryBar;
  final Widget searchResults;
  final Widget? preview;

  Future<void> _animateSheet(
    DraggableScrollableController controller,
    bool visible,
    ValueNotifier<bool> animating,
  ) async {
    if (!controller.isAttached) {
      animating.value = false;
      return;
    }

    final target = visible ? _sheetPeekSize : 0.0;
    if ((controller.size - target).abs() < 0.01) {
      animating.value = false;
      return;
    }
    animating.value = true;
    await controller.animateTo(
      target,
      duration: visible ? 750.ms : 400.ms,
      curve: visible
          ? const ElasticOutCurve(0.8)
          : Curves.fastEaseInToSlowEaseOut,
    );
    animating.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final visible = preview != null;
    final controller = useDraggableScrollableController();
    final animating = useState(false);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _animateSheet(controller, visible, animating);
      });
      return null;
    }, [controller, visible, MediaQuery.sizeOf(context).width]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = Stack(
          clipBehavior: Clip.none,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedPadding(
                  duration: visible ? 750.ms : 400.ms,
                  curve: visible
                      ? const ElasticOutCurve(0.8)
                      : Curves.fastEaseInToSlowEaseOut,
                  padding: EdgeInsets.only(
                    bottom: visible
                        ? constraints.maxHeight * _sheetPeekSize
                        : _spacing,
                    top: _spacing,
                    left: _spacing,
                    right: _spacing,
                  ),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: _spacing,
                        children: [
                          queryBar,
                          Expanded(child: searchResults),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: _BottomPreviewSheet(
                controller: controller,
                preview: preview,
                animating: animating.value,
              ),
            ),
          ],
        );

        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return stack;
        }

        return SizedBox.expand(child: stack);
      },
    );
  }
}

class _PrimarySearchFrame extends StatelessWidget {
  const _PrimarySearchFrame({
    required this.queryBar,
    required this.searchResults,
    this.preview,
    this.actionBar,
  });

  final Widget queryBar;
  final Widget searchResults;
  final Widget? preview;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxSearchFrameWidth),
      child: _FloatingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _spacing,
          children: [
            queryBar,
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: searchResults),
                  _InlinePreviewSlot(preview: preview),
                ],
              ),
            ),
            ?actionBar,
          ],
        ),
      ),
    );
  }
}

class _InlinePreviewSlot extends StatelessWidget {
  const _InlinePreviewSlot({required this.preview});

  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;

    return AnimatedSwitcher(
      duration: 420.ms,
      reverseDuration: 180.ms,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, animation) {
        final elastic = CurvedAnimation(
          parent: animation,
          curve: const ElasticOutCurve(0.82),
          reverseCurve: Curves.easeInCubic,
        );

        return ClipRect(
          child: SizeTransition(
            sizeFactor: elastic,
            axis: Axis.horizontal,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: preview == null
          ? const SizedBox(key: ValueKey("no-inline-preview"))
          : ConstrainedBox(
              key: const ValueKey("inline-preview"),
              constraints: const BoxConstraints(maxWidth: _maxPreviewWidth),
              child: Padding(
                padding: const EdgeInsets.only(left: _spacing),
                child: SingleChildScrollView(child: preview),
              ),
            ),
    );
  }
}

class _ExternalPreviewSlot extends StatelessWidget {
  const _ExternalPreviewSlot({required this.preview});

  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;

    return AnimatedSwitcher(
      duration: 460.ms,
      reverseDuration: 180.ms,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: const ElasticOutCurve(0.5),
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );
      },
      child: preview == null
          ? const SizedBox(key: ValueKey("no-external-preview"))
          : ConstrainedBox(
              key: const ValueKey("external-preview"),
              constraints: const BoxConstraints(maxWidth: 320),
              child: _PreviewCard(child: SingleChildScrollView(child: preview)),
            ),
    );
  }
}

class _BottomPreviewSheet extends StatelessWidget {
  const _BottomPreviewSheet({
    required this.controller,
    required this.preview,
    this.animating = false,
  });

  final DraggableScrollableController controller;
  final Widget? preview;
  final bool animating;

  @override
  Widget build(BuildContext context) {
    final visible = preview != null;

    return IgnorePointer(
      ignoring: !visible,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          if (visible && !animating && notification.extent < _sheetPeekSize) {
            controller.jumpTo(_sheetPeekSize);
          }
          return false;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.0,
          minChildSize: 0.0,
          maxChildSize: _sheetMaxSize,
          shouldCloseOnMinExtent: false,
          snap: visible,
          snapSizes: visible ? const [_sheetPeekSize, _sheetMaxSize] : null,
          controller: controller,
          snapAnimationDuration: 200.ms,
          builder: (context, scrollController) {
            final surfaceColor = Theme.of(context).colorScheme.surface;

            return Surface(
              color: surfaceColor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Section(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      const SliverPersistentHeader(
                        pinned: true,
                        delegate: DraggableSheetHandleDelegate(),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          bottom: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: AnimatedSwitcher(
                            duration: 180.ms,
                            reverseDuration: 750.ms,
                            switchInCurve: Curves.linear,
                            switchOutCurve: Curves.linear,
                            child: preview ?? const SizedBox.shrink(),
                            transitionBuilder: (child, _) => child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(child: child);
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Surface(
      color: colors.surfaceContainer,
      child: Material(
        color: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.72),
            width: context.isDarkMode ? 1.2 : 0.4,
          ),
        ),
        elevation: 3,
        shadowColor: colors.shadow,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(16.0), child: child),
      ),
    );
  }
}
