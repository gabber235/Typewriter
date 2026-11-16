import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const organizationSearchResultType = SearchResultType(
  id: "organization",
  rowRendererId: "organization",
  label: "Organization",
);

const createOrganizationSearchResultType = SearchResultType(
  id: "create_organization",
  rowRendererId: "create_organization",
  label: "Create Organization",
);

/// Searches the person's organizations by name, beside the command to create
/// one more. An empty search lists them all. While the list loads again the
/// known organizations stay listed, marked stale, and a failure shows beside
/// them. Opening and creating are separate commands; this source performs no
/// mutation.
ListSearchSource<Object> organizationsSearchSource(
  ValueListenable<AsyncValue<List<skir.Organization>>> organizations,
) => ListSearchSource<Object>(
  items: organizations,
  type: organizationSearchResultType,
  sectionId: "organizations",
  title: "Organizations",
  fixed: const [_CreateOrganization()],
  listsWithoutQuery: true,
  retainsStale: true,
  idOf: (item) => switch (item) {
    final skir.Organization organization =>
      organization.organizationId.toSurrealQl(),
    _ => createOrganizationSearchResultType.id,
  },
  typeOf: (item) => item is skir.Organization
      ? organizationSearchResultType
      : createOrganizationSearchResultType,
  titleOf: (item) => switch (item) {
    final skir.Organization organization => organization.name,
    _ => "Create Organization",
  },
  termsOf: (item) => switch (item) {
    final skir.Organization organization => [organization.name],
    _ => ["Create Organization"],
  },
);

/// The command to create an organization, as a result beside them.
final class _CreateOrganization {
  const _CreateOrganization();
}
