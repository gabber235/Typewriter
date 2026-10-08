import "package:typewriter_panel/typewriter_panel.dart";

extension AuthoringSessionRef on Ref {
  AuthoringSessionAccess readAuthoringSession() {
    final organizationId = read(organizationIdProvider);
    final realmId = read(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    return AuthoringSessionAccess(
      notifier: read(provider.notifier),
      state: read(provider),
    );
  }
}

extension AuthoringSessionWidgetRef on WidgetRef {
  AuthoringSessionAccess readAuthoringSession() {
    final organizationId = read(organizationIdProvider);
    final realmId = read(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    return AuthoringSessionAccess(
      notifier: read(provider.notifier),
      state: read(provider),
    );
  }
}
