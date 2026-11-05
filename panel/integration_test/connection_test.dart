import "support/remote_session.dart";
import "support/scenarios.dart";
import "support/stack.dart" as stack;

void main() {
  faultScenario(
    "CONN-1",
    "a dropped link shows waiting for connection, and saved work is intact once it returns",
    Demonstrates.edgeCase,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.create("Book", "Before the drop $run");
      final book = panel.openResource;
      await (await remoteSession("ada"))
          .expectSaved(book, ["title"], "Before the drop $run");

      await stack.natsLink(enabled: false);
      await panel.expectVisible("Waiting for connection");
      await panel.capture("waiting-for-connection");

      await stack.natsLink(enabled: true);
      await panel.expectHidden("Waiting for connection");
      expect(await panel.fieldValue("Title"), "Before the drop $run");
      await panel.type("Title", "After the drop $run");
      await panel.capture("edited-after-drop");
      // A session opened after the drop, so its own reconnect cannot hide or
      // fake the save.
      await (await remoteSession("ada"))
          .expectSaved(book, ["title"], "After the drop $run");
      await panel.capture("editing-resumed");
    },
  );

  faultScenario(
    "CONN-1.E1",
    "a Realm that goes away pauses editing, and editing resumes with the work intact once it returns",
    Demonstrates.edgeCase,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.create("Book", "Before the outage $run");
      final book = panel.openResource;

      // The panel learns a host is gone only when its 30 second heartbeat
      // goes stale for two minutes, and that it is back from the next one.
      const heartbeat = Duration(minutes: 3);
      await stack.realmLink(enabled: false);
      await panel.expectVisible("Realm connection lost", within: heartbeat);
      await panel.capture("realm-connection-lost");

      await stack.realmLink(enabled: true);
      await panel.expectHidden("Realm connection lost", within: heartbeat);
      expect(await panel.fieldValue("Title"), "Before the outage $run");
      await panel.type("Title", "After the outage $run");
      await panel.capture("edited-after-outage");
      await (await remoteSession("ada"))
          .expectSaved(book, ["title"], "After the outage $run");
      await panel.capture("realm-resumed");
    },
  );
}
