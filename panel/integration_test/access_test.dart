import "support/remote_session.dart";
import "support/scenarios.dart";

void main() {
  scenario(
    "AUTH-1",
    "a signed in user signs out and lands on sign in with no session left",
    Demonstrates.happyPath,
    (panel) async {
      await panel.signIn("ada");
      await panel.restart();
      await panel.expectVisible("ada");
      await panel.signOut();
      await panel.capture("signed-out");
      await panel.restart();
      await panel.expectVisible("Sign in");
      await panel.expectHidden("ada");
    },
  );

  scenario(
    "REALM-1",
    "an owner opens their organization's realm",
    Demonstrates.happyPath,
    (panel) async {
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.expectVisible("Every book of the realm");
      await panel.capture("realm-open");
    },
  );

  scenario(
    "REALM-1.E1",
    "a user outside the organization sees none of its realms",
    Demonstrates.edgeCase,
    (panel) async {
      // The membership scenarios have grace join Acme, so this one makes her
      // a stranger again whatever ran before it.
      await (await remoteSession("ada")).forget("Acme", "grace");
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.expectVisible("Every book of the realm");
      final realm = panel.address;
      await panel.startElsewhere();
      await panel.signIn("grace");
      await panel.expectHidden("Acme");
      await panel.visit(realm);
      await panel.expectVisible("You do not have access to this organization.");
      await panel.capture("realm-refused");
      await panel.expectHidden(
        "Every book of the realm",
        settled: const Duration(seconds: 10),
      );
      expect(panel.address, isNot(realm));
    },
  );

  scenario(
    "ORG-1",
    "a user creates an organization and becomes its owner",
    Demonstrates.happyPath,
    (panel) async {
      await panel.signIn("grace");
      // A name of its own per run: organization names are unique, and a rerun
      // shares the stack.
      final name = "studio_${DateTime.now().millisecondsSinceEpoch}";
      await panel.type("Enter organization name", name);
      await panel.press("Create");
      await panel.open("Members");
      await panel.expectVisible("grace");
      await panel.expectVisible("founder");
      await panel.capture("owner");
    },
  );
}
