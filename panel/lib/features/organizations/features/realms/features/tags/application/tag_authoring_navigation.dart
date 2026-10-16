import "package:typewriter_panel/typewriter_panel.dart";

final class TagAuthoringNavigationAdapter
    implements AuthoringResourceNavigationAdapter {
  const TagAuthoringNavigationAdapter();

  @override
  Future<void> open(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) async {
    await reveal(ref, resource, isCurrent: isCurrent);
    if (!ref.mounted || !(isCurrent?.call() ?? true)) return;
    ref.read(selectionProvider.notifier).select(resource);
  }

  @override
  Future<void> reveal(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) => ref
      .read(appRouterProvider)
      .navigate(
        OrganizationRoute(
          organizationId: resource.organizationId.id,
          children: [
            RealmRoute(
              realmId: resource.realmId.id,
              children: [const TagsRoute()],
            ),
          ],
        ),
        isCurrent: isCurrent,
      );
}
