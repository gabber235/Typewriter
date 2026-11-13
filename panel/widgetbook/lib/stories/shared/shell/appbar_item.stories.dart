import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/shell.dart";
import "package:widgetbook_workspace/support/story.dart";

/// One [AppBarItem] of every sizing policy in a real app bar, each labelled
/// by its policy: Fixed never changes, Adaptive shortens to its icon, Wide
/// only leaves and Compact only arrives once the bar runs out of room.
@widgetbook.UseCase(name: "Every policy", type: AppBarItem)
Widget appBarItemUseCase(BuildContext context) {
  return Story(const [], at: PanelLocation.component(_bar(context)));
}

/// The [AppBarItemGate] of each item: its labels name what the gate tells
/// the item, Visible or Hidden. A hidden item keeps its place in the tree,
/// so its focus and popups survive, but takes no width, focus or taps.
@widgetbook.UseCase(name: "Visibility", type: AppBarItemGate)
Widget appBarItemGateUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(_bar(context, reportsVisibility: true)),
  );
}

Widget _bar(BuildContext context, {bool reportsVisibility = false}) {
  final width = context.knobs.object.dropdown(
    label: "Width",
    options: storyBarWidths.keys.toList(),
    initialOption: "Wide",
  );
  return SizedBox(
    width: storyBarWidths[width],
    child: CustomAppBar(
      navigation: AppBarBreadcrumbs(children: storyBreadcrumbs(1)),
      primary: storyPrimaryItem(),
      actions: [
        for (final item in storyPolicyItems())
          AppBarItem(
            key: item.key!,
            policy: item.policy,
            child: reportsVisibility
                ? _Visibility(policy: item.policy)
                : item.child,
          ),
      ],
    ),
  );
}

/// An app bar control naming its policy and whether its gate shows it.
class _Visibility extends StatelessWidget {
  const _Visibility({required this.policy});

  final AppBarItemPolicy policy;

  @override
  Widget build(BuildContext context) {
    final name = switch (policy) {
      FixedAppBarItem() => "Fixed",
      AdaptiveAppBarItem() => "Adaptive",
      ExpandedOnlyAppBarItem() => "Wide only",
      CompactOnlyAppBarItem() => "Compact only",
    };
    final state = AppBarItemVisibility.of(context) ? "visible" : "hidden";
    return storyBarControl(
      "$name $state",
      Icones(MaterialSymbols.info_rounded),
    );
  }
}
