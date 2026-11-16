import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/doubles/realm.dart";

/// [document] saved in a [FakeRealm] named [name] that holds every save until
/// the test answers it, and the panel's editing of it; the realm is scoped by
/// [id]. Both live until the test ends.
({FakeRealm realm, RealmEditing workspace}) heldRealmEditing(
  AuthoringDocument document, {
  required String id,
  required String name,
}) {
  final realm = FakeRealm(
    scope: AuthoringScope(
      organizationId: skir.recordId("organization:$id"),
      realmId: skir.recordId("realm_instance:$id"),
    ),
    name: name,
    document: document,
  )..holdSaves = true;
  final submissions = ScopedWorkSession();
  addTearDown(submissions.dispose);
  final workspace = RealmEditing(
    persistence: realm.persistence,
    submissions: submissions,
    initial: document,
  );
  addTearDown(workspace.dispose);
  addTearDown(realm.close);
  return (realm: realm, workspace: workspace);
}
