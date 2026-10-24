import "package:typewriter_panel/typewriter_panel.dart";

part "appbar_item.freezed.dart";

/// One sizing and presence policy for a canonical app bar child.
///
/// Equal collapse orders change together. Successive orders shorten controls
/// progressively. Conditional items refer to their own group rather than a
/// global screen breakpoint.
@freezed
sealed class AppBarItemPolicy with _$AppBarItemPolicy {
  const factory AppBarItemPolicy.fixed() = FixedAppBarItem;
  const factory AppBarItemPolicy.adaptive(int collapseOrder) =
      AdaptiveAppBarItem;
  const factory AppBarItemPolicy.expandedOnly(int collapseOrder) =
      ExpandedOnlyAppBarItem;
  const factory AppBarItemPolicy.compactOnly(int collapseOrder) =
      CompactOnlyAppBarItem;

  const AppBarItemPolicy._();
  int? get order => switch (this) {
    FixedAppBarItem() => null,
    AdaptiveAppBarItem(:final collapseOrder) ||
    ExpandedOnlyAppBarItem(:final collapseOrder) ||
    CompactOnlyAppBarItem(:final collapseOrder) => collapseOrder,
  };
}

/// Composes one feature control with its sizing policy.
///
/// Keys identify controls within a route. Width changes retain the child,
/// including its popup and focus nodes. Adaptive children must render an icon
/// at the bar's compact extent, as [AppBarControl] does.
class AppBarItem extends StatelessWidget {
  const AppBarItem({
    required this.policy,
    required this.child,
    required Key key,
  }) : super(key: key);
  factory AppBarItem.fixed({required Widget child, required Key key}) =>
      AppBarItem(
        key: key,
        policy: const AppBarItemPolicy.fixed(),
        child: child,
      );
  factory AppBarItem.adaptive({
    required Widget child,
    required int collapseOrder,
    required Key key,
  }) => AppBarItem(
    key: key,
    policy: AppBarItemPolicy.adaptive(collapseOrder),
    child: child,
  );
  factory AppBarItem.expandedOnly({
    required Widget child,
    required int collapseOrder,
    required Key key,
  }) => AppBarItem(
    key: key,
    policy: AppBarItemPolicy.expandedOnly(collapseOrder),
    child: child,
  );
  factory AppBarItem.compactOnly({
    required Widget child,
    required int collapseOrder,
    required Key key,
  }) => AppBarItem(
    key: key,
    policy: AppBarItemPolicy.compactOnly(collapseOrder),
    child: child,
  );
  final AppBarItemPolicy policy;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppBarItemGate(child: child);
}

/// Interaction eligibility from the final app bar allocation.
///
/// Transient measurement never changes this value. Popup and shortcut owners
/// can observe it to retire a surface when its conditional trigger disappears.
class AppBarItemVisibility extends InheritedWidget {
  const AppBarItemVisibility({
    required this.visible,
    required super.child,
    super.key,
  });
  final bool visible;
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppBarItemVisibility>()
          ?.visible ??
      true;
  @override
  bool updateShouldNotify(AppBarItemVisibility oldWidget) =>
      visible != oldWidget.visible;
}

/// Carries final allocation without treating measurement as a new decision.
class AppBarItemConstraints extends BoxConstraints {
  const AppBarItemConstraints.measuring({super.maxHeight}) : allocation = null;

  const AppBarItemConstraints.allocated({
    required AppBarItemAllocation this.allocation,
    super.minWidth,
    super.maxWidth,
    super.maxHeight,
  });

  final AppBarItemAllocation? allocation;

  @override
  bool operator ==(Object other) =>
      other is AppBarItemConstraints &&
      allocation == other.allocation &&
      super == other;
  @override
  int get hashCode => Object.hash(super.hashCode, allocation);
}

/// Keeps a conditional item's tree mounted while excluding hidden interaction.
class AppBarItemGate extends StatefulWidget {
  const AppBarItemGate({required this.child, super.key});
  final Widget child;
  @override
  State<AppBarItemGate> createState() => _AppBarItemGateState();
}

class _AppBarItemGateState extends State<AppBarItemGate> {
  AppBarItemAllocation? _allocation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints case AppBarItemConstraints(:final allocation?)) {
        _allocation = allocation;
      }
      // Before the first final fit, measurement remains live.
      final active = _allocation is! HiddenAppBarAllocation;
      final visible = _allocation == null || _allocation!.width > 0;
      return AppBarItemVisibility(
        visible: visible,
        child: ExcludeFocus(
          excluding: !visible,
          child: ExcludeSemantics(
            excluding: !visible,
            child: IgnorePointer(
              ignoring: !visible,
              child: TickerMode(enabled: active, child: widget.child),
            ),
          ),
        ),
      );
    },
  );
}
