import "support/remote_session.dart";
import "support/scenarios.dart";

void main() {
  scenario(
    "PUB-1",
    "publishing valid content reports everything published",
    Demonstrates.happyPath,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.createBookWithPage("Ready $run", page: "Ready Chapter $run");
      await panel.press("Realm inbox");
      await panel.expectVisible("Ready Chapter $run");
      await panel.expectVisible("Added");
      await panel.press("Publish");
      await panel.expectVisible("Everything is published");
      await panel.capture("published");
    },
  );

  scenario(
    "PUB-1.E1",
    "publishing broken content is blocked and names the problem",
    Demonstrates.edgeCase,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.createBookWithPage(
        "Broken $run",
        page: "Broken Chapter $run",
      );
      await panel.search("Broken $run", choose: "Broken $run");
      // A broken book blocks every publication in the realm, so it goes away
      // even when this scenario fails partway.
      (await remoteSession("ada")).deleteAfterwards(panel.openResource);
      await panel.field("Title").submit("");
      await panel.press("Realm inbox");
      await panel.expectVisible("Publish blocked");
      await panel.expectVisible("Text must not be blank");
      await panel.capture("publish-blocked");
    },
  );
}
