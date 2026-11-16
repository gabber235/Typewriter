import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");

  testWidgets("Shift+P opens the inbox on the first issue", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.reportPublication(
      blockedPublicationStatus(problem: publicationProblem()),
    );
    await panel.pressShifted(LogicalKeyboardKey.keyP);
    expect(panel.focused, contains("A required Page value is missing"));
  });

  testWidgets("with no issues the inbox opens on the first saved change", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.reportPublication(readyPublicationStatus(resource: "page"));
    await panel.pressShifted(LogicalKeyboardKey.keyP);
    expect(panel.focused, isNot(anyOf(isNull, "Close")));
    expect(panel.focused, contains("Added"));
  });
}
