import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/publication.dart";
import "../../../../../support/test_utils.dart";

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:inbox"),
  realmId: skir.recordId("service:inbox"),
);

RealmInboxState _state([int issues = 0]) => RealmInboxState(
  publication: const RealmPublicationView.checking(),
  issues: [
    for (var i = 0; i < issues; i++)
      RealmInboxIssue.localFinding(
        PortablePresentationDiagnostic(
          code: "issue$i",
          message: "Problem $i",
          severity: skir.DiagnosticSeverity.error,
        ),
      ),
  ],
);

void main() {
  test("projection preserves attention priority across publication states", () {
    final ready =
        (readyPublicationStatus() as skir.PublicationStatus_readyWrapper).value;
    final variants = <RealmPublicationView, RealmInboxStatus>{
      RealmPublicationView.empty(
        skir.PublicationStatus_Empty(notices: const []),
      ): const RealmInboxStatus.quiet(),
      RealmPublicationView.current(
        skir.PublicationStatus_Current(
          selected: skir.PublicationId(value: "published"),
          notices: const [],
        ),
      ): const RealmInboxStatus.quiet(),
      RealmPublicationView.ready(
        ready,
        RealmPublishCommand(
          ready.candidate,
          () async => skir.PublicationResult.noChanges,
        ),
      ): const RealmInboxStatus.ready(),
      RealmPublicationView.blocked(
        (blockedPublicationStatus() as skir.PublicationStatus_blockedWrapper)
            .value,
      ): const RealmInboxStatus.attention(
        0,
      ),
      const RealmPublicationView.checking(): const RealmInboxStatus.checking(),
      RealmPublicationView.publishing(
        skir.PublicationStatus_Publishing(
          publication: skir.PublicationId(value: "publishing"),
          phase: skir.PublicationActivationPhase.storing,
          releasing: ready.changes,
          next: skir.PublicationPendingReview.defaultInstance,
        ),
      ): const RealmInboxStatus.publishing(),
      const RealmPublicationView.requestActive():
          const RealmInboxStatus.publishing(),
      const RealmPublicationView.unavailable("Offline"):
          const RealmInboxStatus.attention(0),
      const RealmPublicationView.uncertain("Unknown"):
          const RealmInboxStatus.attention(0),
    };
    for (final entry in variants.entries) {
      final state = RealmInboxState(publication: entry.key);
      expect(state.buttonStatus, entry.value);
      expect(
        state.copyWith(issues: _state(2).issues).buttonStatus,
        const RealmInboxStatus.attention(2),
      );
    }
    final first = _state(2);
    final changedDetails = first.copyWith(
      issues: first.issues.reversed.toList(),
    );
    expect(first.buttonStatus, changedDetails.buttonStatus);
  });

  for (final reduced in [false, true]) {
    testWidgets(
      "status commits together and keeps focus, reduced motion $reduced",
      (tester) async {
        final state = ValueNotifier(_state());
        addTearDown(state.dispose);
        await _mount(tester, state, reduced: reduced);
        final button = find.descendant(
          of: find.byType(RealmInboxButton),
          matching: find.byType(FilledButton),
        );
        final originalButton = tester.element(button);
        final control = find.byType(AppBarControl);
        Focus.of(tester.element(find.byType(AnimatedStatusContent)))
            .requestFocus();
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        final oldStyle = tester.widget<AppBarControl>(control).style;
        state.value = _state(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        state.value = _state(2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 69));
        expect(
          tester.widget<AppBarControl>(control).semanticLabel,
          "Realm inbox. Checking",
        );
        expect(tester.widget<AppBarControl>(control).style, oldStyle);
        expect(find.byIcon(Icons.error_outline), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        final displayed = tester.widget<AppBarControl>(control);
        expect(displayed.semanticLabel, "Realm inbox. 2 issues");
        expect(displayed.style, isNot(oldStyle));
        expect(find.text("2 issues"), findsOneWidget);
        expect(find.text("1 issue"), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        if (reduced) {
          expect(find.text("Checking"), findsNothing);
          expect(find.byIcon(Icons.sync), findsNothing);
        }
        expect(tester.element(button), same(originalButton));
        expect(FocusManager.instance.primaryFocus, same(focus));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(RealmInboxView), findsOneWidget);
      },
    );
  }

  testWidgets("popup reads current issues before the display deadline", (
    tester,
  ) async {
    final state = ValueNotifier(_state(1));
    addTearDown(state.dispose);
    await _mount(tester, state, reduced: true);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    final popup = tester.element(find.byType(RealmInboxView));
    state.value = _state(2);
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<RealmInboxView>(find.byType(RealmInboxView)).state.issues,
      hasLength(2),
    );
    expect(
      tester.widget<AppBarControl>(find.byType(AppBarControl)).semanticLabel,
      "Realm inbox. 1 issue",
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<AppBarControl>(find.byType(AppBarControl)).semanticLabel,
      "Realm inbox. 2 issues",
    );
    expect(tester.element(find.byType(RealmInboxView)), same(popup));
    await tester.pumpAndSettle();
  });

  testWidgets("changing realm resets pending presentation immediately", (
    tester,
  ) async {
    final state = ValueNotifier(_state(1));
    final selected = ValueNotifier(_scope);
    final nextScope = _scope.copyWith(realmId: skir.recordId("service:next"));
    addTearDown(state.dispose);
    addTearDown(selected.dispose);
    await _mount(
      tester,
      state,
      selected: selected,
      extra: [realmInboxProvider(nextScope).overrideWithValue(_state(3))],
    );
    state.value = _state(2);
    await tester.pump();
    selected.value = nextScope;
    await tester.pump();
    await tester.pump();
    expect(find.text("3 issues"), findsOneWidget);
    expect(find.text("1 issue"), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("2 issues"), findsNothing);
    expect(find.text("3 issues"), findsOneWidget);
  });
}

Future<void> _mount(
  WidgetTester tester,
  ValueNotifier<RealmInboxState> state, {
  bool reduced = false,
  ValueNotifier<AuthoringScope>? selected,
  List<Override> extra = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final work = ScopedWorkSession();
  addTearDown(work.dispose);
  await tester.pumpTestApp(
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: const Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: WorkspaceActivityButton(),
          ),
        ),
      ),
    ),
    overrides: [
      selectedAuthoringScopeProvider.overrideWith((ref) {
        selected?.addListener(ref.invalidateSelf);
        ref.onDispose(() => selected?.removeListener(ref.invalidateSelf));
        return selected?.value ?? _scope;
      }),
      realmInboxProvider(_scope).overrideWith((ref) {
        state.addListener(ref.invalidateSelf);
        ref.onDispose(() => state.removeListener(ref.invalidateSelf));
        return state.value;
      }),
      workingAuthoringDocumentProvider(_scope)
          .overrideWith((ref) => const AsyncLoading()),
      localWorkControllerProvider.overrideWithValue(work),
      ...extra,
    ],
  );
}
