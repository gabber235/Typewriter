import "support/remote_session.dart";
import "support/scenarios.dart";

// Join codes read as the invite address the panel shares.
final _joinCode = RegExp(r"https://panel\.typewritermc\.com/join/\S+");

void main() {
  scenario(
    "JOIN-1",
    "a user joins with a code, the owner approves, and the user reaches the realm",
    Demonstrates.happyPath,
    (panel) async {
      await (await remoteSession("ada")).forget("Acme", "alan");
      await panel.signIn("ada");
      await panel.open("Acme", "Join Codes");
      await panel.press("Generate Join Code");
      final code = await panel.read(_joinCode);

      await panel.startElsewhere();
      await panel.signIn("alan");
      await panel.type("Invite URL or code", code);
      await panel.press("Join");
      await panel.expectVisible("Awaiting approval");

      await panel.startElsewhere();
      await panel.signIn("ada");
      await panel.open("Acme", "Join Requests");
      await panel.row("alan").choose("Accept");
      await panel.press("writer");
      await panel.press("Confirm & Add Member");
      await panel.expectHidden("alan");

      await panel.startElsewhere();
      await panel.signIn("alan");
      await panel.open("Acme", "Realm");
      await panel.expectVisible("Every book of the realm");
      await panel.capture("joined-realm");
    },
  );

  scenario(
    "JOIN-1.E1",
    "a declined request gives no access",
    Demonstrates.edgeCase,
    (panel) async {
      await (await remoteSession("ada")).forget("Acme", "grace");
      await panel.signIn("ada");
      await panel.open("Acme", "Join Codes");
      final acme = panel.address;
      await panel.press("Generate Join Code");
      final code = await panel.read(_joinCode);

      await panel.startElsewhere();
      await panel.signIn("grace");
      await panel.type("Invite URL or code", code);
      await panel.press("Join");
      await panel.expectVisible("Awaiting approval");

      await panel.startElsewhere();
      await panel.signIn("ada");
      await panel.open("Acme", "Join Requests");
      await panel.row("grace").choose("Decline");
      await panel.press("Decline");
      await panel.expectHidden("grace");

      await panel.startElsewhere();
      await panel.signIn("grace");
      await panel.expectHidden("Awaiting approval");
      await panel.expectHidden("Acme");
      await panel.visit(acme);
      await panel.expectVisible("You do not have access to this organization.");
      await panel.capture("declined");
    },
  );

  scenario(
    "JOIN-1.E2",
    "a revoked join code is refused",
    Demonstrates.edgeCase,
    (panel) async {
      await panel.signIn("ada");
      await panel.open("Acme", "Join Codes");
      await panel.press("Generate Join Code");
      final code = await panel.read(_joinCode);
      await panel.row(code).choose("Revoke join code");
      await panel.press("Revoke");
      await panel.expectHidden(code);

      await panel.startElsewhere();
      await panel.signIn("grace");
      await panel.type("Invite URL or code", code);
      await panel.press("Join");
      await panel.expectVisible("Failed to submit join request");
      await panel.expectHidden("Awaiting approval");
      await panel.capture("revoked-code-refused");
    },
  );

  scenario(
    "MEMBER-1",
    "a removed member loses the organization without signing out",
    Demonstrates.happyPath,
    (panel) async {
      await (await remoteSession("ada")).forget("Acme", "barbara");
      await panel.signIn("ada");
      await panel.open("Acme", "Join Codes");
      await panel.press("Generate Join Code");
      final code = await panel.read(_joinCode);

      await panel.startElsewhere();
      await panel.signIn("barbara");
      await panel.type("Invite URL or code", code);
      await panel.press("Join");

      await panel.startElsewhere();
      await panel.signIn("ada");
      await panel.open("Acme", "Join Requests");
      await panel.row("barbara").choose("Accept");
      await panel.press("writer");
      await panel.press("Confirm & Add Member");

      await panel.startElsewhere();
      await panel.signIn("barbara");
      await panel.open("Acme", "Members");
      await panel.expectVisible("barbara");
      final owner = await remoteSession("ada");
      await owner.removeMember("Acme", "barbara");
      await panel.expectVisible(
        "You no longer have access to this organization.",
      );
      await panel.expectHidden("Acme");
      await panel.capture("membership-removed");
    },
  );
}
