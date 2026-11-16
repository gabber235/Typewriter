import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "organization_items_search.freezed.dart";

/// The sources of the selected organization's members, join codes, join
/// requests and services, each found by name and shown with its second line.
///
/// Each source lists only the organization the route selects, and nothing
/// while that organization's list cannot be read.
List<SearchSource> organizationItemSources(Ref ref) => [
  ListSearchSource<skir.OrganizationMember>(
    items: ref.valued(memberSearchItemsProvider),
    type: memberSearchResultType,
    title: "Members",
    idOf: (member) => member.userId.id,
    titleOf: (member) => member.searchTitle,
    termsOf: (member) => [
      ?member.name,
      ?member.email,
      for (final role in member.roles) role.name,
    ],
  ),
  ListSearchSource<JoinCodeSearchItem>(
    items: ref.valued(joinCodeSearchItemsProvider),
    type: joinCodeSearchResultType,
    title: "Join codes",
    idOf: (item) => item.code.code.id,
    titleOf: (item) => "Join code",
    termsOf: (item) => ["Join code", for (final role in item.roles) role.name],
  ),
  ListSearchSource<skir.OrganizationJoinRequest>(
    items: ref.valued(joinRequestSearchItemsProvider),
    type: joinRequestSearchResultType,
    title: "Join requests",
    idOf: (request) => request.requestId.id,
    titleOf: (request) => request.searchTitle,
    termsOf: (request) => [?request.userName, ?request.userEmail],
  ),
  ListSearchSource<ServiceSearchItem>(
    items: ref.valued(serviceSearchItemsProvider),
    type: serviceSearchResultType,
    title: "Services",
    idOf: (item) => item.service.serviceId.id,
    titleOf: (item) => item.service.displayName,
    termsOf: (item) => [item.service.displayName, item.service.name],
  ),
];

/// The commands that open the page listing each organization item and select
/// it there, one per item kind.
List<SearchCommand> openOrganizationItemCommands(skir.RecordId organization) {
  PageRouteInfo membership(PageRouteInfo page) => OrganizationRoute(
    organizationId: organization.id,
    children: [
      MembersRoute(children: [page]),
    ],
  );
  return [
    _openItemCommand<skir.OrganizationMember>(
      type: memberSearchResultType,
      label: "Open Member",
      page: membership(const MemberListRoute()),
      selectableOf: (member) => MemberIdentifier(member.userId),
    ),
    _openItemCommand<JoinCodeSearchItem>(
      type: joinCodeSearchResultType,
      label: "Open Join Code",
      page: membership(const JoinCodesRoute()),
      selectableOf: (item) => JoinCodeIdentifier(item.code.code),
    ),
    _openItemCommand<skir.OrganizationJoinRequest>(
      type: joinRequestSearchResultType,
      label: "Open Join Request",
      page: membership(const JoinRequestsRoute()),
      selectableOf: (request) => JoinRequestIdentifier(request.requestId),
    ),
    _openItemCommand<ServiceSearchItem>(
      type: serviceSearchResultType,
      label: "Open Service",
      page: OrganizationRoute(
        organizationId: organization.id,
        children: [ServicesRoute()],
      ),
      selectableOf: (item) => item.selectable,
    ),
  ];
}

/// The open command of each organization item kind, by result type.
SearchCommandId openOrganizationItemCommandId(SearchResultType type) =>
    SearchCommandId("${type.id}.open");

SearchCommand _openItemCommand<T extends Object>({
  required SearchResultType type,
  required String label,
  required PageRouteInfo page,
  required SelectableIdentifier Function(T item) selectableOf,
}) => SearchCommand.single<T>(
  id: openOrganizationItemCommandId(type),
  presentation: SearchCommandPresentation(
    label: label,
    icon: MaterialSymbols.open_in_new_rounded,
  ),
  matcher: SearchResultMatcher(type),
  execute: (context, item, target) async => SearchCommandResult.completed(
    hostEffects: [RevealSelectableEffect(page, selectableOf(item))],
  ),
);

/// Opens [page] and reveals [selectable] on it: selected alone, inspected,
/// and its row focused.
@freezed
abstract class RevealSelectableEffect
    with _$RevealSelectableEffect
    implements SearchHostEffect {
  const factory RevealSelectableEffect(
    PageRouteInfo page,
    SelectableIdentifier selectable,
  ) = _RevealSelectableEffect;
}
