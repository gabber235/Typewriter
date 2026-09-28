import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

Future<void> showAddRelationSearch(
  BuildContext context, {
  required skir.ResourceId host,
  required DataPath fieldPath,
  skir.CreationAttachment? ownershipForNewTarget,
  FutureOr<DataValue?> Function(AuthoringCreationOption option)? initialValue,
}) => showSearchModal<void>(
  context,
  (ref, promptContext) {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (organizationId == null || realmId == null) {
      throw ApiException.badRequest("No Realm selected");
    }
    return relationSearchContribution(
      ref: ref,
      organizationId: organizationId,
      realmId: realmId,
      host: host,
      field: ref.valued(relationFieldForResourceProvider(host, fieldPath)),
      ownershipForNewTarget: ownershipForNewTarget,
      initialValue: initialValue,
    );
  },
  searchHint: "Add related resource",
  rowRenderers: relationSearchRowRenderers,
);

SearchContribution relationSearchContribution({
  required Ref ref,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
  required skir.ResourceId host,
  required ValueListenable<AsyncValue<RealmRelationField>> field,
  skir.CreationAttachment? ownershipForNewTarget,
  FutureOr<DataValue?> Function(AuthoringCreationOption option)? initialValue,
  SearchHostEffect? Function(CreatedAuthoringResource resource)? createdEffect,
}) {
  final catalog = ref.valued(realmEditorCatalogProvider);
  final target = field.value.value?.target;
  return SearchContribution(
    session: SearchSession(
      source: [
        RealmAuthoringSearchSource(
          ref: ref,
          organizationId: organizationId,
          realmId: realmId,
          contextResource: host,
          assignableTo: target == null ? null : NamedType(target),
        ).inSection(id: "related.resources", title: "Existing resources"),
        AuthoringCreationSearchSource(catalog, field: field),
      ].merged(),
      scope: relationFieldSearchScope(field: field, catalog: catalog),
      interaction: SearchInteraction(
        activation: SearchActivation.command(
          resolve: (result) => switch (result.type) {
            authoringResourceSearchResultType => linkRelatedResourceCommandId,
            authoringCreationSearchResultType => createRelatedResourceCommandId,
            _ => null,
          },
          dependencies: [field],
        ),
        selectionMode: SearchSelectionMode.single,
        commands: relationFieldCommands(
          ref: ref,
          host: host,
          field: field,
          ownershipForNewTarget: ownershipForNewTarget,
          initialValue: initialValue,
          createdEffect: createdEffect,
        ),
      ),
    ),
  );
}

final relationSearchRowRenderers = <String, SearchResultRowBuilder>{
  authoringResourceSearchResultType.rowRendererId: (context) =>
      AuthoringSearchResultItem(
        payload: context.result.payload as AuthoringSearchResultPayload,
        focused: context.focused,
        selected: context.selected,
        loading: context.loading,
        onTap: context.onTap,
        shortcutActivator: context.shortcutActivator,
      ),
  authoringCreationSearchResultType.rowRendererId:
      buildAuthoringCreationSearchResultItem,
};
