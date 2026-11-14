/// The app bar and sidebar parts the shell stories assemble: breadcrumbs,
/// app bar controls for every sizing policy, and the widths a bar is shown
/// at.
library;

import "package:typewriter_panel/typewriter_panel.dart";

/// The bar widths an app bar story offers, from a wide desktop down to a
/// bar narrower than its controls.
const storyBarWidths = {
  "Wide": 1200.0,
  "Medium": 760.0,
  "Narrow": 520.0,
  "Phone": 340.0,
  "Too narrow": 220.0,
};

/// [count] breadcrumbs of a workspace path; the second has a very long
/// name, so a long path shows how the breadcrumbs scroll.
List<Widget> storyBreadcrumbs(int count) => [
  for (final name in [
    "Acme",
    "The Very Long Named Interactive Storytelling Guild Realm",
    "The Lost Village",
    "Act one",
    "Arrival",
  ].take(count))
    Button(label: name, onPressed: () {}),
];

/// An app bar control with [icon] and [label], which shortens to the icon
/// when the bar gives it a compact width.
Widget storyBarControl(
  String label,
  Widget icon, {
  ButtonFace face = ButtonFace.quiet,
  double? preferredWidth,
}) => AppBarControl(
  face: face,
  tooltip: label,
  semanticLabel: label,
  preferredWidth: preferredWidth,
  onPressed: () {},
  contentBuilder: (context, compact) =>
      AppBarControlContent(compact: compact, icon: icon, label: label),
);

/// The primary search control every story bar shows; it shortens first.
AppBarItem storyPrimaryItem() => AppBarItem.adaptive(
  key: const ValueKey("search"),
  collapseOrder: 0,
  child: storyBarControl(
    "Search",
    const Icon(Icons.search_rounded, size: 18),
    face: ButtonFace.filled,
    preferredWidth: 360,
  ),
);

/// One action for every sizing policy, each labelled by its policy: a fixed
/// one, an adaptive one that shortens second, one shown only while the bar
/// is wide and one shown only once the bar is compact.
List<AppBarItem> storyPolicyItems() => [
  AppBarItem.fixed(
    key: const ValueKey("fixed"),
    child: storyBarControl("Fixed", Icones(MaterialSymbols.key)),
  ),
  AppBarItem.adaptive(
    key: const ValueKey("adaptive"),
    collapseOrder: 1,
    child: storyBarControl(
      "Adaptive",
      Icones(MaterialSymbols.schedule_rounded),
    ),
  ),
  AppBarItem.expandedOnly(
    key: const ValueKey("expanded"),
    collapseOrder: 2,
    child: storyBarControl("Wide only", Icones(MaterialSymbols.palette)),
  ),
  AppBarItem.compactOnly(
    key: const ValueKey("compact"),
    collapseOrder: 2,
    child: storyBarControl("Compact only", Icones(MaterialSymbols.dns)),
  ),
];

/// Sidebar content without routes: a header, the external links and the
/// account footer, the way an organization sidebar ends.
class StorySidebarContent extends StatelessWidget {
  const StorySidebarContent({this.compact = false, super.key});

  /// Whether the footer shows the account menu alone.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SidebarHeader(text: "Help"),
        const SupportSidebarLink(expand: true),
        const DocumentationSidebarLink(expand: true),
        const Spacer(),
        FooterSidebarLinks(compact: compact),
      ],
    );
  }
}
