import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final class _RecordingAuth extends Auth {
  int signOutCalls = 0;

  @override
  Future<OidcUserManager?> build() async => null;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  testWidgets("voluntary sign out waits for protected work confirmation", (
    tester,
  ) async {
    const scope = LocalWorkScope(userId: "user", organizationId: null);
    final controller = WorkSessionLossController(() => scope, () => true);
    final auth = _RecordingAuth();
    var routerReads = 0;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workSessionLossProvider.overrideWithValue(controller),
          appRouterProvider.overrideWith((ref) {
            routerReads++;
            throw StateError("Account policy must not construct routing");
          }),
          authProvider.overrideWith(() => auth),
        ],
        child: const MaterialApp(home: Scaffold(body: SignOutButton())),
      ),
    );

    await tester.tap(find.text("Sign out"));
    await tester.pumpAndSettle();
    expect(find.text("Leave this work session?"), findsOneWidget);
    await tester.tap(find.text("Stay"));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 0);

    await tester.tap(find.text("Sign out"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Leave"));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
    expect(routerReads, 0);
  });
}
