import "package:typewriter_panel/typewriter_panel.dart";

part "custom_appbar_layout.freezed.dart";

/// The natural width of one mounted item, independent of its previous fit.
@freezed
abstract class AppBarItemMeasurement with _$AppBarItemMeasurement {
  const factory AppBarItemMeasurement({
    required AppBarItemPolicy policy,
    required double width,
  }) = _AppBarItemMeasurement;
  const AppBarItemMeasurement._();

  AppBarItemAllocation allocate(
    Set<int> collapsed,
    double compactExtent,
  ) => switch (policy) {
    FixedAppBarItem() => AppBarItemAllocation.visible(width),
    AdaptiveAppBarItem(:final collapseOrder) => AppBarItemAllocation.visible(
      collapsed.contains(collapseOrder) ? min(width, compactExtent) : width,
    ),
    ExpandedOnlyAppBarItem(:final collapseOrder) =>
      collapsed.contains(collapseOrder)
          ? const AppBarItemAllocation.hidden()
          : AppBarItemAllocation.visible(width),
    CompactOnlyAppBarItem(:final collapseOrder) =>
      collapsed.contains(collapseOrder)
          ? AppBarItemAllocation.visible(width)
          : const AppBarItemAllocation.hidden(),
  };
}

/// Hidden allocation has no interactive or visual extent.
@freezed
sealed class AppBarItemAllocation with _$AppBarItemAllocation {
  const factory AppBarItemAllocation.hidden() = HiddenAppBarAllocation;
  const factory AppBarItemAllocation.visible(double extent) =
      VisibleAppBarAllocation;
  const AppBarItemAllocation._();
  double get width => switch (this) {
    HiddenAppBarAllocation() => 0,
    VisibleAppBarAllocation(:final extent) => extent,
  };
}

/// A complete final fit shared by painting, input, semantics, and focus gating.
@freezed
abstract class AppBarFit with _$AppBarFit {
  const factory AppBarFit({
    required double contentWidth,
    required double navigationWidth,
    required AppBarItemAllocation primary,
    required List<AppBarItemAllocation> actions,
  }) = _AppBarFit;
  const AppBarFit._();
}

/// Fits the canonical controls by collapsing ordered groups once each.
@freezed
abstract class AppBarMeasurements with _$AppBarMeasurements {
  const factory AppBarMeasurements({
    required double navigationWidth,
    required AppBarItemMeasurement primary,
    required List<AppBarItemMeasurement> actions,
  }) = _AppBarMeasurements;
  const AppBarMeasurements._();

  AppBarFit fit({
    required double availableWidth,
    required double compactExtent,
    required double spacing,
    double minimumNavigationExtent = 48,
    double debugReservation = 0,
  }) {
    final items = [primary, ...actions];
    final collapsed = <int>{};
    final orders =
        items.map((item) => item.policy.order).nonNulls.toSet().toList()
          ..sort();
    final navigationMinimum = min(navigationWidth, minimumNavigationExtent);
    List<AppBarItemAllocation> resolve() => [
      for (final item in items) item.allocate(collapsed, compactExtent),
    ];
    double widthWithGaps(List<AppBarItemAllocation> allocation) {
      final count =
          allocation.where((item) => item.width > 0).length +
          (navigationMinimum > 0 ? 1 : 0);
      return allocation.fold(0.0, (sum, item) => sum + item.width) +
          max(0, count - 1) * spacing;
    }

    for (final order in orders) {
      if (widthWithGaps(resolve()) + navigationMinimum + debugReservation <=
          availableWidth) {
        break;
      }
      collapsed.add(order);
    }
    final allocation = resolve();
    final controlsWidth = widthWithGaps(allocation);
    final contentWidth = max(
      availableWidth,
      controlsWidth + navigationMinimum + debugReservation,
    );
    return AppBarFit(
      contentWidth: contentWidth,
      navigationWidth: min(
        navigationWidth,
        max(navigationMinimum, contentWidth - controlsWidth - debugReservation),
      ),
      primary: allocation.first,
      actions: allocation.skip(1).toList(),
    );
  }
}

/// Positions one navigation region, primary control, and keyed action list.
///
/// One persistent viewport keeps essential compact controls reachable even
/// below their combined minimum width. Natural measurement uses the same
/// mounted children; only the final allocation changes interaction eligibility.
class CustomAppBarLayout extends StatelessWidget {
  CustomAppBarLayout({
    required this.navigation,
    required this.primary,
    required this.actions,
    required this.spacing,
    this.minimumNavigationExtent = 48,
    this.debugReservation = 0,
    super.key,
  }) {
    final keys = <Key>{};
    for (final item in [primary, ...actions]) {
      if (item.key == null || !keys.add(item.key!)) {
        throw ArgumentError("App bar controls require unique keys");
      }
      if (item.policy.order case final order? when order < 0) {
        throw ArgumentError("Collapse order cannot be negative");
      }
    }
    for (final extent in [spacing, minimumNavigationExtent, debugReservation]) {
      if (!extent.isFinite || extent < 0) {
        throw ArgumentError("App bar extents must be finite and nonnegative");
      }
    }
  }
  final Widget navigation;
  final AppBarItem primary;
  final List<AppBarItem> actions;
  final double spacing;
  final double minimumNavigationExtent;
  final double debugReservation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _AppBarRenderLayout(
        availableWidth: constraints.maxWidth,
        height: constraints.maxHeight,
        spacing: spacing,
        minimumNavigationExtent: minimumNavigationExtent,
        debugReservation: debugReservation,
        children: [
          _AppBarPlaced(
            key: const ValueKey("navigation"),
            policy: const AppBarItemPolicy.fixed(),
            child: AppBarItemGate(child: navigation),
          ),
          _AppBarPlaced(
            key: primary.key,
            policy: primary.policy,
            child: primary,
          ),
          for (final item in actions)
            _AppBarPlaced(key: item.key, policy: item.policy, child: item),
        ],
      ),
    ),
  );
}

class _AppBarParentData extends ContainerBoxParentData<RenderBox> {
  AppBarItemPolicy policy = const AppBarItemPolicy.fixed();
  AppBarItemAllocation allocation = const AppBarItemAllocation.hidden();
}

class _AppBarPlaced extends ParentDataWidget<_AppBarParentData> {
  const _AppBarPlaced({required this.policy, required super.child, super.key});
  final AppBarItemPolicy policy;
  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _AppBarParentData;
    if (data.policy == policy) return;
    data.policy = policy;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _AppBarRenderLayout;
}

class _AppBarRenderLayout extends MultiChildRenderObjectWidget {
  const _AppBarRenderLayout({
    required this.availableWidth,
    required this.height,
    required this.spacing,
    required this.minimumNavigationExtent,
    required this.debugReservation,
    required super.children,
  });
  final double availableWidth;
  final double height;
  final double spacing;
  final double minimumNavigationExtent;
  final double debugReservation;
  @override
  RenderCustomAppBarLayout createRenderObject(BuildContext context) =>
      RenderCustomAppBarLayout(
        availableWidth: availableWidth,
        height: height,
        spacing: spacing,
        minimumNavigationExtent: minimumNavigationExtent,
        debugReservation: debugReservation,
      );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderCustomAppBarLayout renderObject,
  ) {
    renderObject.configure(
      availableWidth: availableWidth,
      height: height,
      spacing: spacing,
      minimumNavigationExtent: minimumNavigationExtent,
      debugReservation: debugReservation,
    );
  }
}

/// Owns geometry for the canonical children, without feature or popup policy.
class RenderCustomAppBarLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AppBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AppBarParentData> {
  RenderCustomAppBarLayout({
    required double availableWidth,
    required double height,
    required double spacing,
    required double minimumNavigationExtent,
    required double debugReservation,
  }) {
    configure(
      availableWidth: availableWidth,
      height: height,
      spacing: spacing,
      minimumNavigationExtent: minimumNavigationExtent,
      debugReservation: debugReservation,
    );
  }
  late double _availableWidth;
  late double _height;
  late double _spacing;
  late double _minimumNavigationExtent;
  late double _debugReservation;
  void configure({
    required double availableWidth,
    required double height,
    required double spacing,
    required double minimumNavigationExtent,
    required double debugReservation,
  }) {
    if (!availableWidth.isFinite || !height.isFinite || height <= 0) {
      throw ArgumentError(
        "The app bar needs bounded width and positive height",
      );
    }
    _availableWidth = availableWidth;
    _height = height;
    _spacing = spacing;
    _minimumNavigationExtent = minimumNavigationExtent;
    _debugReservation = debugReservation;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AppBarParentData) {
      child.parentData = _AppBarParentData();
    }
  }

  List<RenderBox> get _children {
    final result = <RenderBox>[];
    for (
      var child = firstChild;
      child != null;
      child = (child.parentData! as _AppBarParentData).nextSibling
    ) {
      result.add(child);
    }
    return result;
  }

  @override
  void performLayout() {
    final children = _children;
    for (final child in children) {
      child.layout(
        AppBarItemConstraints.measuring(maxHeight: _height),
        parentUsesSize: true,
      );
    }
    AppBarItemMeasurement measure(RenderBox child) => AppBarItemMeasurement(
      policy: (child.parentData! as _AppBarParentData).policy,
      width: child.size.width,
    );
    final fit =
        AppBarMeasurements(
          navigationWidth: children[0].size.width,
          primary: measure(children[1]),
          actions: children.skip(2).map(measure).toList(),
        ).fit(
          availableWidth: _availableWidth,
          compactExtent: _height,
          spacing: _spacing,
          minimumNavigationExtent: _minimumNavigationExtent,
          debugReservation: _debugReservation,
        );
    size = constraints.constrain(Size(fit.contentWidth, _height));
    final allocations = [
      AppBarItemAllocation.visible(fit.navigationWidth),
      fit.primary,
      ...fit.actions,
    ];
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      final allocation = allocations[index];
      final data = child.parentData! as _AppBarParentData;
      final resumed =
          data.allocation is HiddenAppBarAllocation &&
          allocation is VisibleAppBarAllocation;
      data.allocation = allocation;
      final visible = allocation.width > 0;
      child.layout(
        AppBarItemConstraints.allocated(
          allocation: allocation,
          // Empty and hidden children retain natural constraints. Tight zero
          // width can change an empty AnimatedSwitcher height on each pass.
          minWidth: visible ? allocation.width : 0,
          maxWidth: visible ? allocation.width : double.infinity,
          maxHeight: _height,
        ),
        parentUsesSize: true,
      );
      if (resumed ||
          (!visible &&
              allocation is VisibleAppBarAllocation &&
              child.size.width > 0)) {
        _scheduleMeasurement();
      }
    }
    void position(RenderBox child, double x) {
      (child.parentData! as _AppBarParentData).offset = Offset(
        x,
        (_height - child.size.height) / 2,
      );
    }

    position(children.first, 0);
    var right = size.width - _debugReservation;
    var hasAction = false;
    for (var index = children.length - 1; index >= 2; index--) {
      if (allocations[index].width == 0) continue;
      if (hasAction) right -= _spacing;
      right -= allocations[index].width;
      position(children[index], right);
      hasAction = true;
    }
    final minimumX =
        fit.navigationWidth + (fit.navigationWidth > 0 ? _spacing : 0);
    final maximumX = right - (hasAction ? _spacing : 0) - fit.primary.width;
    position(
      children[1],
      ((size.width - fit.primary.width) / 2).clamp(
        minimumX,
        max(minimumX, maximumX),
      ),
    );
  }

  bool _measurementScheduled = false;

  // Resuming a provider can rebuild a child during final allocation, after its
  // natural width was measured. Read that width again on the following frame.
  void _scheduleMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (attached) markNeedsLayout();
    });
  }

  @override
  bool paintsChild(RenderBox child) =>
      (child.parentData! as _AppBarParentData).allocation.width > 0;
  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _children.where(paintsChild)) {
      context.paintChild(
        child,
        offset + (child.parentData! as _AppBarParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _children.reversed.where(paintsChild)) {
      final data = child.parentData! as _AppBarParentData;
      if (result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, point) => child.hitTest(result, position: point),
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = (child.parentData! as _AppBarParentData).offset;
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    _children.where(paintsChild).forEach(visitor);
  }
}
