import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final class TagAuthoringNavigationAdapter
    implements AuthoringResourceNavigationAdapter {
  const TagAuthoringNavigationAdapter();

  @override
  bool supports(String handler) => handler == "typewriter.tags";

  @override
  Future<void> open(Ref ref, OpenAuthoringResourceEffect effect) async {
    await ref
        .read(appRouterProvider)
        .navigate(
          OrganizationRoute(
            organizationId: effect.organizationId.id,
            children: [
              RealmRoute(
                realmId: effect.realmId.id,
                children: [const TagsRoute()],
              ),
            ],
          ),
        );
    ref
        .read(selectionProvider.notifier)
        .select(TagIdentifier(effect.resourceId));
  }
}
