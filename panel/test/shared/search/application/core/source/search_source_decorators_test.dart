// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// Every decorator wraps one inner source and owns its lifecycle: the
/// decorated source starts, stops and describes itself through the inner one.
void main() {
  final decorators = <String, SearchSource Function(SearchSource inner)>{
    "cached": (inner) => inner.cached(),
    "debounced": (inner) => inner.debounced(const Duration(milliseconds: 100)),
    "open gated": (inner) => inner.gated((context) => true),
    "limited": (inner) => inner.limited((context) => 10),
    "ranked": (inner) => inner.ranked([
      SearchRankField(text: (result) => result.title, weight: 1),
    ]),
    "distinct": (inner) => inner.distinct(),
  };

  for (final MapEntry(key: name, value: decorate) in decorators.entries) {
    group("a $name source", () {
      test("starts and stops its inner source exactly once", () {
        final inner = FakeSearchSource();
        final source = decorate(inner);

        source.initialize(SearchQueryContext.empty);
        expect(inner.initializeCount, 1);
        source.dispose();

        expect(inner.disposeCount, 1);
      });

      test("offers the selectors of its inner source", () {
        const selectors = [KeyValueSelectorDefinition(id: "tag", key: "#")];
        final source = decorate(FakeSearchSource(selectors: selectors));
        addTearDown(source.dispose);

        expect(source.selectors, selectors);
      });

      test("shows the results its inner source finds", () {
        final inner = FakeSearchSource();
        final source = decorate(inner);
        addTearDown(source.dispose);
        final snapshots = <SearchSourceSnapshot>[];
        final subscription = source.snapshots.listen(snapshots.add);
        addTearDown(subscription.cancel);
        source.initialize(SearchQueryContext.empty);

        inner.emitSnapshot(readySnapshot(nodes: [resultNode("alpha")]));

        expect(resultIds(snapshots.last), ["alpha"]);
      });
    });
  }
}
