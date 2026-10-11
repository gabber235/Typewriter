import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../support/test_utils.dart";

void main() {
  test("page copying can clear its Book owner", () {
    final page = Page(
      pageId: _page,
      bookId: _book,
      name: "Page",
      configuration: skir.TypeSelection.unknown,
      chapter: "",
      priority: 0,
    );

    expect(page.copyWith(bookId: null).bookId, isNull);
  });

  testWidgets(
    "sidebar Edit keyboard action inspects the page without toggling it",
    (tester) async {
      final image = await tester.runAsync(() async {
        final recorder = PictureRecorder();
        Canvas(recorder);
        return recorder.endRecording().toImage(1, 1);
      });
      final avatar = NetworkImage(mockUserInfo.avatarUrl!);
      PaintingBinding.instance.imageCache.putIfAbsent(
        avatar,
        () => OneFrameImageStreamCompleter(
          Future.value(ImageInfo(image: image!)),
        ),
      );
      addTearDown(() => PaintingBinding.instance.imageCache.evict(avatar));
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = _state(chapter: skir.DataValue.unfilled);
      final page = Page.fromAuthoring(state.snapshot!.resources.single);
      late WidgetRef ref;
      await tester.pumpTestApp(
        overrides: [
          ...appearanceProviderOverrides(),
          ...authProviderOverrides(),
          organizationIdProvider.overrideWithValue(_organization),
          realmIdProvider.overrideWithValue(_realm),
          bookIdProvider.overrideWith((ref) => _book),
          pageIdProvider.overrideWith((ref) => null),
          ...authoringFixtureOverrides(
            document: fixtureAuthoringDocument(
              books: [
                Book(
                  bookId: _book,
                  title: "Book",
                  color: Colors.blue,
                  icon: "mdi:book",
                  tagIds: const [],
                ),
              ],
              pages: [page.copyWith(bookId: _book)],
            ),
          ),
        ],
        child: Consumer(
          builder: (context, value, child) {
            ref = value;
            value.watch(selectionProvider);
            return const Scaffold(
              body: SizedBox(width: 320, child: BookSidebarContent()),
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      for (var tab = 0; tab < 12; tab++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (ref
            .read(actionShortcutsProvider)
            .containsKey("book_sidebar_page_edit")) {
          break;
        }
      }
      expect(
        ref.read(actionShortcutsProvider).containsKey("book_sidebar_page_edit"),
        isTrue,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(ref.read(selectionProvider), [
        AuthoringResourceIdentifier(
          organizationId: _organization,
          realmId: _realm,
          resourceId: _page,
        ),
      ]);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(ref.read(selectionProvider), hasLength(1));
      ref.read(selectionProvider.notifier).selectAll([]);
      await tester.pump();
      await tester.longPress(find.byType(AuthoringSubjectRole));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Edit"));
      await tester.pumpAndSettle();
      expect(ref.read(selectionProvider), [
        AuthoringResourceIdentifier(
          organizationId: _organization,
          realmId: _realm,
          resourceId: _page,
        ),
      ]);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    "Edit selects the scoped page and repeated Edit keeps it selected",
    (tester) async {
      final harness = await _mount(tester, _state());
      harness.ref.inspectPage(_page);
      await tester.pump();
      final expected = AuthoringResourceIdentifier(
        organizationId: _organization,
        realmId: _realm,
        resourceId: _page,
      );
      expect(harness.ref.read(selectionProvider), [expected]);
      final resolved =
          harness.ref.read(selectedProvider).requireValue.single
              as AuthoringSelectableResource;
      expect(resolved.id, expected);
      expect(resolved.resource.id, _page);
      harness.ref.inspectPage(_page);
      await tester.pump();
      expect(harness.ref.read(selectionProvider), [expected]);
      expect(harness.transport.requests, isEmpty);
    },
  );

  for (final chapter in [
    skir.DataValue.unfilled,
    skir.DataValue.wrapStringValue(""),
    _namedChapter("old"),
  ]) {
    testWidgets("chapter changes preserve the exact authored expectation", (
      tester,
    ) async {
      final harness = await _mount(tester, _state(chapter: chapter));
      final result = harness.workspace.edit(
        label: "Move page to chapter",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.setFieldPayload(
          resource: _page,
          fields: ["chapter"],
          payload: skir.DataValue.wrapStringValue("new"),
        ),
      ) as AuthoringEditStaged;
      unawaited(harness.workspace.save(result.group));
      await tester.pump();
      final submitted = harness.transport.requests.single.edit;
      final set = submitted.intents.single as skir.EditIntent_setValueWrapper;
      expect(set.value.value.authoredString, "new");
      expect(set.value.value.authoredActualType, chapter.authoredActualType);
      expect(
        submitted.expectations
            .whereType<skir.EditExpectation_valueWrapper>()
            .single
            .value
            .expected,
        chapter,
      );
      expect(
        harness.workspace.document
            .resource(_page)!
            .authoredField("chapter")!
            .authoredString,
        "new",
      );
    });
  }

  testWidgets("chapter batch is atomic when a participating page is missing", (
    tester,
  ) async {
    final harness = await _mount(tester, _state());
    final result = harness.workspace.edit(
      label: "Rename chapter",
      apply: (edit) {
        for (final id in [_page, _second]) {
          edit.setFieldPayload(
            resource: id,
            fields: ["chapter"],
            payload: skir.DataValue.wrapStringValue("new"),
          );
        }
      },
    );
    expect(result, isA<AuthoringEditRejected>());
    expect(
      harness.workspace.document
          .resource(_page)!
          .authoredField("chapter")!
          .authoredString,
      "old",
    );
    expect(harness.workspace.state.groups, isEmpty);
  });

  testWidgets("chapter batch groups every participating resource", (
    tester,
  ) async {
    final harness = await _mount(
      tester,
      _state(second: skir.DataValue.wrapStringValue("old")),
    );
    final result = harness.workspace.edit(
      label: "Rename chapter",
      policy: EditorCommitPolicy.applyResource,
      apply: (edit) {
        for (final id in [_page, _second]) {
          edit.setFieldPayload(
            resource: id,
            fields: ["chapter"],
            payload: skir.DataValue.wrapStringValue("new"),
          );
        }
      },
    ) as AuthoringEditStaged;
    expect(harness.workspace.state.groups[result.group]!.resources, {
      _page,
      _second,
    });
    unawaited(harness.workspace.save(result.group));
    await tester.pump();
    expect(harness.transport.requests.single.edit.intents, hasLength(2));
  });
}

Future<_Harness> _mount(
  WidgetTester tester,
  AuthoringSessionState state,
) async {
  final transport = ScriptedAuthoringTransport(
    AsyncData(state.confirmedDocument!),
  );
  addTearDown(transport.dispose);
  final harness = _Harness(transport);
  await tester.pumpTestApp(
    overrides: [
      organizationIdProvider.overrideWithValue(_organization),
      realmIdProvider.overrideWithValue(_realm),
      ...authoringFixtureOverrides(initial: state, transport: transport),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        harness.ref = ref;
        ref
          ..watch(selectionProvider)
          ..watch(selectedProvider);
        harness.workspace = ref.watch(
          authoringWorkspaceProvider(
            AuthoringScope(organizationId: _organization, realmId: _realm),
          ),
        );
        return const SizedBox();
      },
    ),
  );
  return harness;
}

final class _Harness {
  _Harness(this.transport);
  final ScriptedAuthoringTransport transport;
  late WidgetRef ref;
  late AuthoringWorkspace workspace;
}

AuthoringSessionState _state({
  skir.DataValue? chapter,
  skir.DataValue? second,
  bool missingChapter = false,
}) => AuthoringSessionState(
  catalog: receivedCheckedEditorCatalog(generation: _generation),
  snapshot: skir.AuthoringState(
    generation: _generation,
    resources: [
      _resource(
        _page,
        chapter ?? skir.DataValue.wrapStringValue("old"),
        missingChapter: missingChapter,
      ),
      if (second != null) _resource(_second, second),
    ],
    links: const [],
    findings: const [],
  ),
);

skir.AuthoringResource _resource(
  skir.ResourceId id,
  skir.DataValue chapter, {
  bool missingChapter = false,
}) => skir.AuthoringResource(
  id: id,
  definition: skir.ResourceDefinitionId(value: "typewriter.page"),
  content: skir.AuthoringRecord(
    configuration: skir.TypeSelection.unknown,
    fields: [
      skir.FieldValue(name: "name", value: skir.DataValue.unfilled),
      if (!missingChapter) skir.FieldValue(name: "chapter", value: chapter),
      skir.FieldValue(name: "priority", value: skir.DataValue.unfilled),
    ],
  ),
);

skir.DataValue _namedChapter(String text, {String type = "Chapter"}) =>
    skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.wrapQualified(
            skir.QualifiedTypeId(namespace: "test", name: type),
          ),
          revision: 1,
        ),
        arguments: const [],
      ),
      payload: skir.DataValue.wrapStringValue(text),
    );

final _page = skir.ResourceId(value: "page:test");
final _second = skir.ResourceId(value: "page:second");
final _generation = skir.CatalogGeneration(value: "catalog:page");
final _organization = skir.recordId("organization:test");
final _realm = skir.recordId("realm:test");

final _book = skir.ResourceId(value: "book:test");
