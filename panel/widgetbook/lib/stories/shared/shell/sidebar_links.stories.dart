import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The sidebar width the link stories render in.
const _sidebarWidth = 220.0;

/// A [SidebarHeader] above a group of links, with each label the panel
/// uses, and a label wider than the sidebar, which wraps.
@widgetbook.UseCase(name: "Default", type: SidebarHeader)
Widget sidebarHeaderUseCase(BuildContext context) {
  final text = context.knobs.object.segmented(
    label: "Text",
    options: const [
      "Organization",
      "Realm",
      "Help",
      "Shared realms of this organization",
    ],
    initialOption: "Organization",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: _sidebarWidth,
        child: SidebarHeader(text: text),
      ),
    ),
  );
}

/// The organization's [SidebarLink]s in the real sidebar: the link of the
/// open page is selected, and Join Requests carries the count of pending
/// requests. Pressing another link opens its page.
@widgetbook.UseCase(name: "Selected by the open page", type: SidebarLink)
Widget sidebarLinkUseCase(BuildContext context) {
  final page = context.knobs.object.dropdown(
    label: "Open page",
    options: const ["Services", "Members", "Join requests", "Join codes"],
    initialOption: "Services",
  );
  final requests = context.knobs.object.segmented(
    label: "Join requests",
    options: const ["None", "Few", "Many"],
    initialOption: "Few",
  );
  final generator = Generator(context.knobs.seed());
  return Story(
    [
      signedIn(ada, organization: acme),
      servicesService(),
      membershipService(
        roles: storyRoles,
        members: storyMembers(generator, 4),
        joinCodes: storyJoinCodes(generator, 2),
        joinRequests: storyJoinRequests(generator, switch (requests) {
          "Few" => 3,
          "Many" => 120,
          _ => 0,
        }),
      ),
    ],
    at: PanelLocation.route(
      organizationPage(switch (page) {
        "Members" => MembersRoute(children: [const MemberListRoute()]),
        "Join requests" => MembersRoute(children: [const JoinRequestsRoute()]),
        "Join codes" => MembersRoute(children: [const JoinCodesRoute()]),
        _ => const ServicesRoute(),
      }),
    ),
  );
}

/// An [ExternalSidebarLink] filling the sidebar's width, with the arrow
/// that says it leaves the panel; a long label wraps, and a trailing count
/// sits before the arrow.
@widgetbook.UseCase(name: "In the sidebar", type: ExternalSidebarLink)
Widget externalSidebarLinkUseCase(BuildContext context) {
  final text = context.knobs.object.segmented(
    label: "Text",
    options: const ["Changelog", "Community showcase and example servers"],
    initialOption: "Changelog",
  );
  final trailing = context.knobs.boolean(label: "Trailing count");
  final width = context.knobs.object.segmented(
    label: "Width",
    options: const ["Sidebar", "Narrowest"],
    initialOption: "Sidebar",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width == "Sidebar" ? _sidebarWidth : kSidebarMinSize,
        child: ExternalSidebarLink(
          icon: Icones(MaterialSymbols.star_rounded),
          text: text,
          url: "https://typewritermc.com",
          trailing: trailing ? const Text("12") : null,
        ),
      ),
    ),
  );
}

/// An [ExternalSidebarLink] as wide as its label, the way a row of links
/// places it.
@widgetbook.UseCase(name: "Fitting its label", type: ExternalSidebarLink)
Widget externalSidebarLinkFittedUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      ExternalSidebarLink(
        icon: Icones(MaterialSymbols.star_rounded),
        text: "Changelog",
        url: "https://typewritermc.com",
        expand: false,
      ),
    ),
  );
}

/// [FooterSidebarLinks] at the foot of the sidebar: Support, Docs and the
/// account menu, or the account menu alone in a compact sidebar.
@widgetbook.UseCase(name: "Default", type: FooterSidebarLinks)
Widget footerSidebarLinksUseCase(BuildContext context) {
  final compact = context.knobs.boolean(label: "Compact");
  return Story(
    [signedIn(ada, organization: acme)],
    at: PanelLocation.component(
      SizedBox(
        width: compact ? 64 : _sidebarWidth,
        child: FooterSidebarLinks(compact: compact),
      ),
    ),
  );
}

/// The [SupportSidebarLink], which opens the Typewriter Discord, filling
/// the sidebar or as wide as its label.
@widgetbook.UseCase(name: "Default", type: SupportSidebarLink)
Widget supportSidebarLinkUseCase(BuildContext context) {
  return _linkStory(context, (expand) => SupportSidebarLink(expand: expand));
}

/// The [DocumentationSidebarLink], which opens the Typewriter docs,
/// filling the sidebar or as wide as its label.
@widgetbook.UseCase(name: "Default", type: DocumentationSidebarLink)
Widget documentationSidebarLinkUseCase(BuildContext context) {
  return _linkStory(
    context,
    (expand) => DocumentationSidebarLink(expand: expand),
  );
}

/// An external link in a sidebar wide column, filling it or as wide as its
/// label.
Widget _linkStory(BuildContext context, Widget Function(bool expand) link) {
  final expand = context.knobs.boolean(label: "Fill width", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: _sidebarWidth,
        child: Align(alignment: Alignment.centerLeft, child: link(expand)),
      ),
    ),
  );
}
