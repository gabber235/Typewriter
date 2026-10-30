import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final narrow in [false, true]) {
    testWidgets("each ${narrow ? "one cell" : "wide"} entry node on a page "
        "graph is one control read as the name it shows", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realmServing(compiledEntryGraphDocument(narrow: narrow)),
      ]);
      await panel.openSurface(compiledEntryPageId);

      for (final name in ["Welcome to the village", "Meet the village guide"]) {
        // What assistive technology reaches: nodes not merged into another.
        final announced = find.semantics
            .byPredicate(
              (node) => node.spoken == name && !node.isMergedIntoParent,
            )
            .evaluate();
        expect(announced, hasLength(1), reason: name);
        expect(announced.single.isTappable, isTrue, reason: name);
      }
    });
  }
}
