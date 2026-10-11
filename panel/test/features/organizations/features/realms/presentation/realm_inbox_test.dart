import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/publication.dart";
import "../../../../../support/test_utils.dart";

void main() {
  final scope = AuthoringScope(
    organizationId: skir.recordId("organization:inbox"),
    realmId: skir.recordId("service:inbox"),
  );
  testWidgets(
    "Normal mode opens a blocked inbox and typing keeps its shortcut inactive",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final work = ScopedWorkSession();
      addTearDown(work.dispose);
      final typing = FocusNode();
      addTearDown(typing.dispose);
      await tester.pumpTestApp(
        child: RealmInboxShortcut(
          child: Scaffold(
            body: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: RealmInboxButton(scope: scope),
                ),
                EditorTextField(
                  focusNode: typing,
                  decoration: const InputDecoration(labelText: "Draft"),
                ),
                const Focus(autofocus: true, child: Text("Realm")),
              ],
            ),
          ),
        ),
        overrides: [
          selectedAuthoringScopeProvider.overrideWithValue(scope),
          realmInteractionProvider.overrideWithValue(
            const RealmInteractionState(
              connectionState: RealmConnectionState.online,
            ),
          ),
          realmInboxProvider(scope).overrideWithValue(
            RealmInboxState(
              publication: RealmPublicationView.blocked(
                (blockedPublicationStatus()
                        as skir.PublicationStatus_blockedWrapper)
                    .value,
              ),
            ),
          ),
          workingAuthoringDocumentProvider(scope)
              .overrideWith((ref) => const AsyncLoading()),
          localWorkControllerProvider.overrideWithValue(work),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RealmInboxButton)),
      );
      await _open(tester);
      expect(find.text("Publish blocked"), findsOneWidget);
      expect(
        container
            .read(actionShortcutsProvider)
            .containsKey("realm_inbox_publish"),
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      typing.requestFocus();
      await tester.pumpAndSettle();
      expect(container.read(currentInteractionModeProvider), isA<InsertMode>());
      await _open(tester);
      expect(find.text("Publish blocked"), findsNothing);
      expect(typing.hasFocus, isTrue);
    },
  );
  testWidgets(
    "readiness removes the whole focused action and departing Publish cannot be invoked",
    (tester) async {
      final work = ScopedWorkSession();
      addTearDown(work.dispose);
      var published = 0;
      final ready =
          (readyPublicationStatus() as skir.PublicationStatus_readyWrapper)
              .value;
      final state = ValueNotifier(
        RealmInboxState(
          publication: RealmPublicationView.ready(
            ready,
            RealmPublishCommand(ready.candidate, () async {
              published++;
              return skir.PublicationResult.noChanges;
            }),
          ),
        ),
      );
      addTearDown(state.dispose);
      await tester.pumpTestApp(
        child: Scaffold(
          body: SizedBox(
            height: 600,
            child: Consumer(
              builder: (context, ref, _) => RealmInboxView(
                state: ref.watch(realmInboxProvider(scope)),
                work: work,
                onClose: () {},
                openLocation: (_) async {},
                resourceLabel: (id) => id.value,
              ),
            ),
          ),
        ),
        overrides: [
          realmInboxProvider(scope).overrideWith((ref) {
            state.addListener(ref.invalidateSelf);
            ref.onDispose(() => state.removeListener(ref.invalidateSelf));
            return state.value;
          }),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RealmInboxView)),
      );
      Focus.of(tester.element(find.text("Publish"))).requestFocus();
      await tester.pumpAndSettle();
      expect(
        container
            .read(actionShortcutsProvider)
            .containsKey("realm_inbox_publish"),
        isTrue,
      );
      state.value = RealmInboxState(
        publication: RealmPublicationView.blocked(
          (blockedPublicationStatus() as skir.PublicationStatus_blockedWrapper)
              .value,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        container
            .read(actionShortcutsProvider)
            .containsKey("realm_inbox_publish"),
        isFalse,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(published, 0);
      expect(find.text("Publish"), findsNothing);
    },
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}
