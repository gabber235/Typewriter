import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  group("Graph move focus", () {
    testWidgets("routes an immediate arrow through the newly activated mode", (
      tester,
    ) async {
      final focusedIds = {
        for (final id in ["a", "b"]) id: _FocusedGraphIdentifier(id: id),
      };
      final focusNodes = {
        for (final id in focusedIds.keys) id: FocusNode(debugLabel: id),
      };
      addTearDown(() {
        for (final node in focusNodes.values) {
          node.dispose();
        }
      });
      final calls = <List<GraphMoveCommitPayload>>[];

      await tester.pumpTestApp(
        settle: false,
        overrides: [
          selectionProvider.overrideWithValue([
            focusedIds["a"]!,
            focusedIds["b"]!,
          ]),
        ],
        child: _MoveGraphHarness(
          focusedIds: focusedIds,
          focusNodes: focusNodes,
          onMoved: calls.add,
        ),
      );
      await tester.pumpAndSettle();
      focusNodes["a"]!.requestFocus();
      await tester.pumpAndSettle();

      await _activateMoveModeWithoutPump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(calls, hasLength(1));
      expect({for (final change in calls.single) change.id.id}, {"a", "b"});
      expect(focusNodes["a"]!.hasPrimaryFocus, isTrue);
    });

    testWidgets("accumulates held key repeats before the next frame", (
      tester,
    ) async {
      final focusedId = _FocusedGraphIdentifier(id: "a");
      final focusNode = FocusNode(debugLabel: "a");
      addTearDown(focusNode.dispose);
      final calls = <List<GraphMoveCommitPayload>>[];

      await tester.pumpTestApp(
        settle: false,
        overrides: [
          selectionProvider.overrideWithValue([focusedId]),
        ],
        child: _MoveGraphHarness(
          focusedIds: {"a": focusedId},
          focusNodes: {"a": focusNode},
          onMoved: calls.add,
        ),
      );
      await tester.pumpAndSettle();
      focusNode.requestFocus();
      await tester.pump();
      await _enterMoveMode(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      for (var index = 0; index < 20; index++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(calls, hasLength(21));
      expect(
        calls.map((call) => call.single.x),
        orderedEquals(List.generate(21, (index) => index + 1)),
      );
      expect(focusNode.hasPrimaryFocus, isTrue);
    });

    testWidgets(
      "moves every selected graph node when focus represents a selected id",
      (tester) async {
        final focusedIds = {
          for (final id in ["a", "b", "c"]) id: _FocusedGraphIdentifier(id: id),
        };
        final focusNodes = {
          for (final id in focusedIds.keys) id: FocusNode(debugLabel: id),
        };
        addTearDown(() {
          for (final node in focusNodes.values) {
            node.dispose();
          }
        });
        final calls = <List<GraphMoveCommitPayload>>[];

        await tester.pumpTestApp(
          settle: false,
          overrides: [
            selectionProvider.overrideWithValue([
              _SelectedGraphIdentifier(id: "a"),
              _SelectedGraphIdentifier(id: "b"),
            ]),
          ],
          child: _MoveGraphHarness(
            focusedIds: focusedIds,
            focusNodes: focusNodes,
            onMoved: calls.add,
          ),
        );
        await tester.pumpAndSettle();
        focusNodes["a"]!.requestFocus();
        await tester.pump();

        await _enterMoveMode(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(calls, hasLength(1));
        expect({for (final change in calls.single) change.id.id}, {"a", "b"});
        expect(focusNodes["a"]!.hasPrimaryFocus, isTrue);
      },
    );

    testWidgets("moves only the focused node when it is not selected", (
      tester,
    ) async {
      final focusedIds = {
        for (final id in ["a", "b", "c"]) id: _FocusedGraphIdentifier(id: id),
      };
      final focusNodes = {
        for (final id in focusedIds.keys) id: FocusNode(debugLabel: id),
      };
      addTearDown(() {
        for (final node in focusNodes.values) {
          node.dispose();
        }
      });
      final calls = <List<GraphMoveCommitPayload>>[];

      await tester.pumpTestApp(
        settle: false,
        overrides: [
          selectionProvider.overrideWithValue([
            _SelectedGraphIdentifier(id: "a"),
            _SelectedGraphIdentifier(id: "b"),
          ]),
        ],
        child: _MoveGraphHarness(
          focusedIds: focusedIds,
          focusNodes: focusNodes,
          onMoved: calls.add,
        ),
      );
      await tester.pumpAndSettle();
      focusNodes["c"]!.requestFocus();
      await tester.pump();

      await _enterMoveMode(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(calls, hasLength(1));
      expect(calls.single, hasLength(1));
      expect(calls.single.single.id.id, "c");
      expect(focusNodes["c"]!.hasPrimaryFocus, isTrue);
    });

    testWidgets("retains focus through repeated committed movement", (
      tester,
    ) async {
      final focusedId = _FocusedGraphIdentifier(id: "a");
      final focusNode = FocusNode(debugLabel: "a");
      addTearDown(focusNode.dispose);
      final calls = <List<GraphMoveCommitPayload>>[];

      await tester.pumpTestApp(
        settle: false,
        overrides: [
          selectionProvider.overrideWithValue([focusedId]),
        ],
        child: _MoveGraphHarness(
          focusedIds: {"a": focusedId},
          focusNodes: {"a": focusNode},
          onMoved: calls.add,
          size: const Size(400, 300),
        ),
      );
      await tester.pumpAndSettle();
      focusNode.requestFocus();
      await tester.pump();
      await _enterMoveMode(tester);

      for (var index = 0; index < 30; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump(const Duration(milliseconds: 16));

        expect(calls, hasLength(index + 1), reason: "move ${index + 1}");
        expect(focusNode.hasPrimaryFocus, isTrue, reason: "move ${index + 1}");
        expect(find.byKey(const ValueKey("node-a")), findsOneWidget);
      }
    });

    testWidgets("retains focus through seeded mixed movement", (tester) async {
      final focusedId = _FocusedGraphIdentifier(id: "a");
      final focusNode = FocusNode(debugLabel: "a");
      addTearDown(focusNode.dispose);
      final calls = <List<GraphMoveCommitPayload>>[];
      final random = Random(240804);
      final keys = [
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
      ];

      await tester.pumpTestApp(
        settle: false,
        overrides: [
          selectionProvider.overrideWithValue([focusedId]),
        ],
        child: _MoveGraphHarness(
          focusedIds: {"a": focusedId},
          focusNodes: {"a": focusNode},
          onMoved: calls.add,
          size: const Size(400, 300),
        ),
      );
      await tester.pumpAndSettle();
      focusNode.requestFocus();
      await tester.pump();
      await _enterMoveMode(tester);

      for (var index = 0; index < 60; index++) {
        await tester.sendKeyEvent(keys[random.nextInt(keys.length)]);
        await tester.pump(Duration(milliseconds: [0, 4, 16][index % 3]));
        expect(calls, hasLength(index + 1), reason: "move ${index + 1}");
        expect(focusNode.hasPrimaryFocus, isTrue, reason: "move ${index + 1}");
      }
    });
  });
}

Future<void> _activateMoveModeWithoutPump(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  expect(
    tester.container().read(currentInteractionModeProvider),
    isA<GraphMoveMode>(),
  );
}

Future<void> _enterMoveMode(WidgetTester tester) async {
  tester
      .container()
      .read(currentInteractionModeProvider.notifier)
      .setMode(GraphMoveMode());
  await tester.pump();
  expect(
    tester.container().read(currentInteractionModeProvider),
    isA<GraphMoveMode>(),
  );
}

class _MoveGraphHarness extends StatefulWidget {
  const _MoveGraphHarness({
    required this.focusedIds,
    required this.focusNodes,
    required this.onMoved,
    this.size = const Size(800, 600),
  });

  final Map<String, _FocusedGraphIdentifier> focusedIds;
  final Map<String, FocusNode> focusNodes;
  final ValueChanged<List<GraphMoveCommitPayload>> onMoved;
  final Size size;

  @override
  State<_MoveGraphHarness> createState() => _MoveGraphHarnessState();
}

class _MoveGraphHarnessState extends State<_MoveGraphHarness> {
  late final Map<String, (int, int)> positions = {
    for (final MapEntry(key: index, value: id)
        in widget.focusedIds.keys.toList().asMap().entries)
      id: (index * 3, 0),
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.fromSize(
        size: widget.size,
        child: Graph(
          data: GraphData(
            cellSize: 50,
            elements: [
              for (final entry in positions.entries)
                GraphElement(
                  id: GraphIdentifier(entry.key),
                  x: entry.value.$1,
                  y: entry.value.$2,
                  width: 2,
                  height: 2,
                  builder: (_) => Selector(
                    selectableId: widget.focusedIds[entry.key]!,
                    focusNode: widget.focusNodes[entry.key]!,
                    builder: (_, _, _) =>
                        SizedBox.expand(key: ValueKey("node-${entry.key}")),
                  ),
                ),
            ],
            edges: const [],
          ),
          onElementsMoved: (changes) {
            widget.onMoved(changes);
            setState(() {
              for (final change in changes) {
                positions[change.id.id] = (change.x, change.y);
              }
            });
          },
        ),
      ),
    );
  }
}

class _FocusedGraphIdentifier extends TestSelectableIdentifier
    implements GraphIdentifier {
  _FocusedGraphIdentifier({required super.id});
}

class _SelectedGraphIdentifier extends TestSelectableIdentifier
    implements GraphIdentifier {
  _SelectedGraphIdentifier({required super.id});
}
