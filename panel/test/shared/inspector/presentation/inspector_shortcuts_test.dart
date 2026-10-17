import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("fitted headings render in mobile and minimum desktop panes", (
    tester,
  ) async {
    final selected = TestSelectableIdentifier(
      id: "a book with an unusually long title that needs fitting",
    );
    for (final width in [400.0, 1600.0]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: width,
            height: 800,
            child: const InspectorScaffold(child: SizedBox()),
          ),
        ),
        overrides: [
          selectionProvider.overrideWithValue([selected]),
          inspectorSizeProvider.overrideWithValue(kInspectorMinSize),
        ],
      );
      expect(
        find.byType(width < 600 ? MobileInspector : DesktopInspector),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      if (width < 600) {
        tester
            .widget<DraggableScrollableSheet>(
              find.byType(DraggableScrollableSheet),
            )
            .controller!
            .jumpTo(0.9);
        await tester.pumpAndSettle();
      }
      final heading = tester.widget<AutoSizeText>(find.byType(AutoSizeText));
      expect(heading.minFontSize, 18);
      expect(heading.maxFontSize, 40);
      expect(heading.textSpan?.toPlainText(), selected.id.formatted);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    "inspector context counts requested selections including unresolved items",
    (tester) async {
      final first = TestSelectableIdentifier(id: "first");
      final second = TestSelectableIdentifier(id: "second");
      await tester.pumpTestApp(
        child: const Center(
          child: SizedBox(
            width: 1600,
            height: 800,
            child: InspectorScaffold(child: SizedBox()),
          ),
        ),
      );
      final container = tester.container(of: find.byType(InspectorScaffold));
      container.read(selectionProvider.notifier).selectAll([first]);
      await tester.pumpAndSettle();
      expect(find.byType(AutoSizeText), findsOneWidget);
      container.read(selectionProvider.notifier).selectAll([first, second]);
      await tester.pumpAndSettle();
      expect(find.byType(AutoSizeText), findsNothing);
      final environments = tester.widgetList<PresentationEnvironment>(
        find.byType(PresentationEnvironment),
      );
      expect(
        environments
            .single
            .bindings[presentationSelectionCountBindingId]
            ?.value
            .authoredInteger
            ?.toInt(),
        2,
      );
      container.read(selectionProvider.notifier).selectAll([first]);
      await tester.pumpAndSettle();
      expect(find.byType(AutoSizeText), findsOneWidget);
      final resolved = container.read(inspectedSelectionProvider).requireValue;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpTestApp(
        child: const Center(
          child: SizedBox(
            width: 1600,
            height: 800,
            child: InspectorScaffold(child: SizedBox()),
          ),
        ),
        overrides: [
          selectionProvider.overrideWithValue([first, second]),
          inspectedSelectionProvider.overrideWith((ref) => AsyncData(resolved)),
        ],
      );
      expect(find.byType(AutoSizeText), findsNothing);
      expect(
        tester
            .widget<PresentationEnvironment>(
              find.byType(PresentationEnvironment),
            )
            .bindings[presentationSelectionCountBindingId]
            ?.value
            .authoredInteger
            ?.toInt(),
        2,
      );
    },
  );

  group("Inspector shortcuts", () {
    testWidgets("organization scaffold hosts the inspector", (tester) async {
      await tester.pumpTestApp(
        child: const OrganizationScaffold(
          child: SizedBox.expand(key: ValueKey("route-content")),
        ),
        overrides: [
          realmInteractionProvider.overrideWith(
            (ref) => const RealmInteractionState(
              connectionState: RealmConnectionState.online,
            ),
          ),
          ...canonicalServicesProviderOverrides(state: DisplayState.noItems),
          ...realmProviderOverrides(),
          ...organizationProviderOverrides(),
          ...organizationsProviderOverrides(state: DisplayState.noItems),
          authUserInfoProvider.overrideWithValue(const AsyncLoading()),
          ...appearanceProviderOverrides(),
          selectionProvider.overrideWithValue([
            TestSelectableIdentifier(id: "test-item"),
          ]),
        ],
        settle: false,
      );
      for (var index = 0; index < 20; index++) {
        await tester.idle();
        await tester.pump();
      }

      expect(find.byType(InspectorScaffold), findsOneWidget);
      expect(find.byType(MobileInspector), findsOneWidget);
      expect(find.byKey(const ValueKey("route-content")), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      for (var index = 0; index < 20; index++) {
        await tester.idle();
        await tester.pump();
      }
    });

    testWidgets("book scaffold hosts one inspector", (tester) async {
      await tester.pumpTestApp(
        child: const BookScaffold(
          child: SizedBox.expand(key: ValueKey("book-route-content")),
        ),
        overrides: [
          realmInteractionProvider.overrideWith(
            (ref) => const RealmInteractionState(
              connectionState: RealmConnectionState.online,
            ),
          ),
          ...canonicalServicesProviderOverrides(state: DisplayState.noItems),
          ...realmProviderOverrides(),
          ...organizationProviderOverrides(),
          ...organizationsProviderOverrides(state: DisplayState.noItems),
          ...appearanceProviderOverrides(),
          authUserInfoProvider.overrideWithValue(const AsyncLoading()),
          selectionProvider.overrideWithValue([
            TestSelectableIdentifier(id: "test-item"),
          ]),
        ],
        settle: false,
      );
      for (var index = 0; index < 20; index++) {
        await tester.idle();
        await tester.pump();
      }

      expect(find.byType(InspectorScaffold), findsOneWidget);
      expect(find.byType(MobileInspector), findsOneWidget);
      expect(find.byKey(const ValueKey("book-route-content")), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      for (var index = 0; index < 20; index++) {
        await tester.idle();
        await tester.pump();
      }
    });

    testWidgets("routed child changes preserve inspector state", (
      tester,
    ) async {
      final routeChild = ValueNotifier<Widget>(
        const SizedBox(key: ValueKey("first")),
      );
      addTearDown(routeChild.dispose);

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1600,
            height: 800,
            child: InspectorScaffold(
              child: ValueListenableBuilder<Widget>(
                valueListenable: routeChild,
                builder: (context, child, _) => child,
              ),
            ),
          ),
        ),
        overrides: [
          selectionProvider.overrideWithValue([
            TestSelectableIdentifier(id: "test-item"),
          ]),
        ],
        settle: true,
      );

      final inspectorElement = tester.element(find.byType(DesktopInspector));
      tester
          .container(of: find.byType(InspectorScaffold))
          .read(inspectorSizeProvider.notifier)
          .size(kInspectorDefaultSize + 50);
      routeChild.value = const SizedBox(key: ValueKey("second"));
      await tester.pump();

      expect(find.byKey(const ValueKey("first")), findsNothing);
      expect(find.byKey(const ValueKey("second")), findsOneWidget);
      expect(
        tester.element(find.byType(DesktopInspector)),
        same(inspectorElement),
      );
      expect(
        tester
            .container(of: find.byType(InspectorScaffold))
            .read(inspectorSizeProvider),
        kInspectorDefaultSize + 50,
      );
    });

    testWidgets("period shrinks and comma expands (small step)", (
      tester,
    ) async {
      final testSelectable = TestSelectableIdentifier(id: "test-item");

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1600,
            height: 800,
            child: InspectorScaffold(child: const SizedBox.shrink()),
          ),
        ),
        overrides: [
          selectionProvider.overrideWithValue([testSelectable]),
        ],
        settle: true,
      );

      final focusScope = tester.widget<FocusScope>(
        find.descendant(
          of: find.byType(DesktopInspector),
          matching: find.byType(FocusScope),
        ),
      );
      focusScope.focusNode?.requestFocus();
      await tester.pumpAndSettle();

      final container = tester.container(of: find.byType(InspectorScaffold));
      final initial = container.read(inspectorSizeProvider);
      expect(initial, equals(kInspectorDefaultSize));

      final inspectorWidth = MediaQuery.of(
        tester.element(find.byType(DesktopInspector)),
      ).size.width;
      final inspectorMax =
          (inspectorWidth * kInspectorMaxFactor).floorToDouble() - 1.0;
      final inspectorMin = min(kInspectorMinSize, inspectorMax);
      final effectiveBefore = initial.clamp(
        max(0.0, inspectorMin),
        inspectorMax,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await tester.pump();

      final afterShrink = container.read(inspectorSizeProvider);
      expect(afterShrink, equals(effectiveBefore - kInspectorResizeSmallStep));

      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.pump();

      final afterExpand = container.read(inspectorSizeProvider);
      expect(afterExpand, equals(effectiveBefore));
    });

    testWidgets("shift+period shrinks and shift+comma expands (large step)", (
      tester,
    ) async {
      final testSelectable = TestSelectableIdentifier(id: "test-item");

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1600,
            height: 800,
            child: InspectorScaffold(child: const SizedBox.shrink()),
          ),
        ),
        overrides: [
          selectionProvider.overrideWithValue([testSelectable]),
        ],
        settle: true,
      );

      final focusScope = tester.widget<FocusScope>(
        find.descendant(
          of: find.byType(DesktopInspector),
          matching: find.byType(FocusScope),
        ),
      );
      focusScope.focusNode?.requestFocus();
      await tester.pumpAndSettle();

      final container = tester.container(of: find.byType(InspectorScaffold));
      final initial = container.read(inspectorSizeProvider);

      final inspectorWidth = MediaQuery.of(
        tester.element(find.byType(DesktopInspector)),
      ).size.width;
      final inspectorMax =
          (inspectorWidth * kInspectorMaxFactor).floorToDouble() - 1.0;
      final inspectorMin = min(kInspectorMinSize, inspectorMax);
      final effectiveBefore = initial.clamp(
        max(0.0, inspectorMin),
        inspectorMax,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.period);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.period);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final afterShrink = container.read(inspectorSizeProvider);
      expect(afterShrink, equals(effectiveBefore - kInspectorResizeLargeStep));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final afterExpand = container.read(inspectorSizeProvider);
      expect(afterExpand, equals(effectiveBefore));
    });
  });
}
