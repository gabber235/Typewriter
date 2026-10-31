import "support/journey.dart";
import "support/wait.dart";

/// The sign in journey against the CI cluster's Authentik, driven from the
/// host: scenarios sign in with the password grant inside the page, because
/// the web sign in leaves the page a scenario runs in.
Future<void> main() => journey(
  "AUTH-2",
  "a user signs in through the identity provider's form, signs out through "
      "its end session, and is asked to sign in again on the next visit",
  Demonstrates.happyPath,
  (user) async {
    final panel = await user.location;
    await user.panelReady();

    await user.tap("Sign in");
    await user.provider.enterUser(user.username);
    await user.capture("provider-sign-in");
    await user.provider.enterPassword(user.password);
    await user.panelReady();
    await user.expectVisible(user.username);
    await user.capture("signed-in");

    await user.provider.endsSessionDuring(() async {
      await user.tap(user.username);
      await user.tap("Logout");
      await user.expectVisible("Sign in");
    });
    await user.capture("signed-out");

    await user.revisit(panel);
    await user.tap("Sign in");
    await until(
      "Authentik asks for the user again instead of signing them in",
      user.provider.asksForUser,
    );
    await user.capture("asked-again");
  },
);
