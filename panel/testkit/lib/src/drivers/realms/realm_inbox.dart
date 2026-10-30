import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/eventually.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// The inbox of the seeded Realm, from a test without widgets.
extension RealmInboxOfWorld on World {
  /// Lets the seeded Realm's publication report [review] and returns the
  /// Realm's inbox once it reviews it.
  Future<RealmInboxState> inboxReviewing(skir.PublicationStatus review) {
    final realm = requireRealm;
    realm.publication.emit(review);
    return container.eventually(
      realmInboxProvider(realm.scope),
      (inbox) => inbox.publication.review == review,
      description: "the inbox reviewing the publication",
    );
  }
}

/// The inbox of the open Realm, as its button shows it.
extension RealmInboxOnPanel on PanelDriver {
  /// Lets the seeded Realm's publication report [review] and the panel run
  /// until the inbox button, which collects changes for a moment, shows it.
  Future<void> reportPublication(skir.PublicationStatus review) async {
    world.requireRealm.publication.emit(review);
    await settleInbox();
  }

  /// Lets the panel run until the inbox button, which collects changes for
  /// a moment, shows what changed.
  Future<void> settleInbox() async {
    await settle();
    await tester.pump(const CoalesceUpdates<RealmInboxStatus>().duration);
    await settle();
  }

  /// Whether the inbox button counts any issue, such as `1 issue`.
  bool get inboxShowsIssues =>
      find.textContaining(RegExp(r"^\d+ issues?$")).evaluate().isNotEmpty;
}
