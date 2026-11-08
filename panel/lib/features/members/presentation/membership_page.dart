import "package:typewriter_panel/typewriter_panel.dart";

/// The frame of one membership page: a primary pane that opens on the first
/// row, a page heading and the page's [tab] below it.
class MembershipPage extends StatelessWidget {
  const MembershipPage({
    required this.id,
    required this.title,
    required this.subtext,
    required this.tab,
    super.key,
  });

  /// The pane id, such as `members`.
  final String id;
  final String title;
  final String subtext;

  /// The sliver that owns the page's live rows.
  final Widget tab;

  @override
  Widget build(BuildContext context) => Pane(
    id: id,
    primary: true,
    openFocus: PaneOpenFocus.firstItem,
    child: Section(
      margin: EdgeInsets.zero,
      child: CustomScrollView(
        primary: true,
        slivers: [
          SliverToBoxAdapter(
            child: PageHeading(title: title, subtext: subtext),
          ),
          SliverPadding(
            padding: EdgeInsets.all(context.spacing.space6),
            sliver: tab,
          ),
        ],
      ),
    ),
  );
}
