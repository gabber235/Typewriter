import "package:freezed_annotation/freezed_annotation.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "organization_search_commands.freezed.dart";

const openOrganizationCommandId = SearchCommandId("organization.open");
const createOrganizationCommandId = SearchCommandId("organization.create");

SearchCommand openOrganizationCommand() =>
    SearchCommand.single<OrganizationData>(
      id: openOrganizationCommandId,
      presentation: const SearchCommandPresentation(
        label: "Open Organization",
        icon: MaterialSymbols.open_in_new_rounded,
      ),
      matcher: const SearchResultMatcher(organizationSearchResultType),
      execute: (context, organization, target) async =>
          SearchCommandResult.completed(
            hostEffects: [OpenOrganizationEffect(organization.organizationId)],
          ),
    );

SearchCommand createOrganizationCommand() => SearchCommand.single<Object>(
  id: createOrganizationCommandId,
  presentation: const SearchCommandPresentation(
    label: "Create Organization",
    icon: MaterialSymbols.add_rounded,
  ),
  matcher: const SearchResultMatcher(createOrganizationSearchResultType),
  execute: (context, value, target) async =>
      const SearchCommandResult.completed(
        hostEffects: [CreateOrganizationEffect()],
      ),
);

@freezed
abstract class OpenOrganizationEffect
    with _$OpenOrganizationEffect
    implements SearchHostEffect {
  const factory OpenOrganizationEffect(skir.RecordId organizationId) =
      _OpenOrganizationEffect;
}

@freezed
abstract class CreateOrganizationEffect
    with _$CreateOrganizationEffect
    implements SearchHostEffect {
  const factory CreateOrganizationEffect() = _CreateOrganizationEffect;
}
