import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final outcome in ProviderLogoutOutcome.values) {
    testWidgets("Logout signs out locally when ending the provider session "
        "${outcome.name}", (tester) async {
      final panel = await tester.pumpPanel([signedIn(ada)]);
      final provider = panel.world.session.providerLogout..outcome = outcome;

      await panel.tapOn(find.text(ada.name));
      await panel.tapOn(find.text("Logout"));

      await panel.eventually(() => expect(find.text("Sign in"), findsWidgets));
      expect(panel.world.session.user, isNull);
      expect(panel.container.read(isAuthenticatedProvider).value, isFalse);
      expect(provider.attempts, 1);
      expect(
        tester.takeException(),
        outcome == ProviderLogoutOutcome.fails
            ? same(provider.failure)
            : isNull,
      );
    });
  }
}
