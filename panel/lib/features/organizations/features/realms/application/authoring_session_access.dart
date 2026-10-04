import "package:hooks_riverpod/hooks_riverpod.dart" show WidgetRef;
import "package:riverpod/riverpod.dart" show Ref;
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authoring_session.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/realm.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";

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
