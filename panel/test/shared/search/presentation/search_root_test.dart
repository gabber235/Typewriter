// ignore_for_file: cascade_invocations

import "package:flutter/material.dart" hide SearchController;
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "../application/core/support/search_core_test_harness.dart";

void main() {
  group("SearchRoot", () {
    testWidgets("child consumer reads the provided controller", (tester) async {
      final source = FakeSearchSource();
      await tester.pumpTestApp(
        child: SearchRoot(
          create: (ref) {
            return SearchController(source: source, baseSelectors: const []);
          },
          child: Consumer(
            builder: (context, ref, child) {
              final controller = ref.watch(searchProvider);
              return Text("Has controller: ${controller != null}");
            },
          ),
        ),
      );

      expect(find.text("Has controller: true"), findsOneWidget);
    });

    testWidgets("child consumer rebuilds when selection changes", (
      tester,
    ) async {
      final source = FakeSearchSource();
      late SearchController controller;

      await tester.pumpTestApp(
        child: SearchRoot(
          create: (ref) => controller = SearchController(
            source: source,
            baseSelectors: const [],
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final controller = ref.watch(searchProvider)!;
              return Text("Selected: ${controller.selectedCount}");
            },
          ),
        ),
      );

      expect(find.text("Selected: 0"), findsOneWidget);

      controller.toggleSelected("alpha");
      await tester.pump();

      expect(find.text("Selected: 1"), findsOneWidget);
    });

    testWidgets("child consumer rebuilds when source snapshot changes", (
      tester,
    ) async {
      final source = FakeSearchSource();

      await tester.pumpTestApp(
        child: SearchRoot(
          create: (ref) =>
              SearchController(source: source, baseSelectors: const []),
          child: Consumer(
            builder: (context, ref, child) {
              final controller = ref.watch(searchProvider)!;
              return Text(
                "Status: ${controller.snapshot.status.name}, nodes: ${controller.snapshot.nodes.length}",
              );
            },
          ),
        ),
      );

      expect(find.text("Status: idle, nodes: 0"), findsOneWidget);

      source.emitSnapshot(readySnapshot(nodes: [resultNode("alpha")]));
      await tester.pump();

      expect(find.text("Status: ready, nodes: 1"), findsOneWidget);
    });

    testWidgets("nested child consumer rebuilds when controller changes", (
      tester,
    ) async {
      final source = FakeSearchSource();
      late SearchController controller;

      await tester.pumpTestApp(
        child: SearchRoot(
          create: (ref) => controller = SearchController(
            source: source,
            baseSelectors: const [],
          ),
          child: const _NestedSearchStatus(),
        ),
      );

      expect(find.text("Nested selected: 0"), findsOneWidget);

      controller.toggleSelected("alpha");
      await tester.pump();

      expect(find.text("Nested selected: 1"), findsOneWidget);
    });

    testWidgets("replacement child consumer receives later updates", (
      tester,
    ) async {
      final source = FakeSearchSource();
      late SearchController controller;
      late VoidCallback replaceChild;

      await tester.pumpTestApp(
        child: _SearchRootChildSwapHost(
          createController: () => controller = SearchController(
            source: source,
            baseSelectors: const [],
          ),
          onReady: (replace) => replaceChild = replace,
        ),
      );

      expect(find.text("First selected: 0"), findsOneWidget);

      replaceChild();
      await tester.pump();

      expect(find.text("First selected: 0"), findsNothing);
      expect(find.text("Second selected: 0"), findsOneWidget);

      controller.toggleSelected("alpha");
      await tester.pump();

      expect(find.text("Second selected: 1"), findsOneWidget);
    });
  });
}

class _SearchRootChildSwapHost extends StatefulWidget {
  const _SearchRootChildSwapHost({
    required this.createController,
    required this.onReady,
  });

  final SearchController Function() createController;
  final void Function(VoidCallback replace) onReady;

  @override
  State<_SearchRootChildSwapHost> createState() =>
      _SearchRootChildSwapHostState();
}

class _SearchRootChildSwapHostState extends State<_SearchRootChildSwapHost> {
  var _secondChild = false;

  @override
  void initState() {
    super.initState();
    widget.onReady(() {
      setState(() {
        _secondChild = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SearchRoot(
      create: (ref) => widget.createController(),
      child: _SearchSelectionText(label: _secondChild ? "Second" : "First"),
    );
  }
}

class _NestedSearchStatus extends StatelessWidget {
  const _NestedSearchStatus();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: _SearchSelectionText(label: "Nested"),
    );
  }
}

class _SearchSelectionText extends ConsumerWidget {
  const _SearchSelectionText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    return Text("$label selected: ${controller.selectedCount}");
  }
}
