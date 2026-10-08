import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../support/test_utils.dart";

void main() {
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
          projectedBookPagesProvider(
            _book,
            "",
          ).overrideWith((ref) => AsyncData([page])),
          ...authoringSessionMockOverrides(
            initial: state,
            onApply: (_) async {},
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
      expect(harness.intents, isEmpty);
    },
  );

  for (final chapter in [
    skir.DataValue.unfilled,
    skir.DataValue.wrapStringValue(""),
    _namedChapter("old"),
  ]) {
    testWidgets("chapter move preserves the exact observed $chapter", (
      tester,
    ) async {
      final state = _state(chapter: chapter);
      final page = Page.fromAuthoring(state.snapshot!.resources.single);
      final drag = PageDrag(
        pageId: page.pageId,
        expectedChapter: page.authoredRecord.authoredField("chapter"),
      );
      final harness = await _mount(tester, state);
      await harness.ref.movePageChapter(
        id: drag.pageId,
        chapter: "new",
        expectedChapter: drag.expectedChapter,
      );
      expect(harness.intents, hasLength(1));
      final set = harness.intents.single as skir.EditIntent_setValueWrapper;
      expect(set.value.at, _field(_page));
      expect(
        set.value.value,
        chapter.withAuthoredPayload(skir.DataValue.wrapStringValue("new")),
      );
    });
  }

  for (final replacement in [
    skir.DataValue.wrapStringValue(""),
    _namedChapter("old", type: "OtherChapter"),
  ]) {
    testWidgets("stale chapter drag does not overwrite $replacement", (
      tester,
    ) async {
      final captured = replacement is skir.DataValue_namedWrapper
          ? _namedChapter("old")
          : skir.DataValue.unfilled;
      final page = Page.fromAuthoring(_resource(_page, captured));
      final drag = PageDrag(
        pageId: page.pageId,
        expectedChapter: page.authoredRecord.authoredField("chapter"),
      );
      final harness = await _mount(tester, _state(chapter: replacement));
      await expectLater(
        harness.ref.movePageChapter(
          id: drag.pageId,
          chapter: "local",
          expectedChapter: drag.expectedChapter,
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            "conflict code",
            409,
          ),
        ),
      );
      expect(harness.intents, isEmpty);
      expect(
        harness.ref
            .readAuthoringSession()
            .state
            .draft!
            .resource(_page)!
            .authoredField("chapter"),
        replacement,
      );
    });
  }

  testWidgets("an unavailable chapter is not treated as authored Unfilled", (
    tester,
  ) async {
    final harness = await _mount(tester, _state(missingChapter: true));
    await expectLater(
      harness.ref.movePageChapter(
        id: _page,
        chapter: "new",
        expectedChapter: skir.DataValue.unfilled,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          "unavailable",
          "The Page chapter is unavailable",
        ),
      ),
    );
    expect(harness.intents, isEmpty);
  });

  testWidgets("chapter group moves empty and named authored values together", (
    tester,
  ) async {
    final state = _state(
      chapter: skir.DataValue.unfilled,
      second: _namedChapter(""),
    );
    final pages = state.snapshot!.resources.map(Page.fromAuthoring).toList();
    final harness = await _mount(tester, state);
    await harness.ref.editPagesChapter(pages, "", "group");
    expect(harness.intents, hasLength(2));
    final sets = harness.intents.cast<skir.EditIntent_setValueWrapper>();
    expect(sets.map((s) => s.value.at), [_field(_page), _field(_second)]);
    expect(sets.map((s) => s.value.value), [
      skir.DataValue.wrapStringValue("group"),
      _namedChapter("group"),
    ]);
  });

  testWidgets("one stale group chapter prevents every batch write", (
    tester,
  ) async {
    final captured = _state(
      chapter: skir.DataValue.unfilled,
      second: skir.DataValue.wrapStringValue(""),
    );
    final pages = captured.snapshot!.resources.map(Page.fromAuthoring).toList();
    final current = _state(
      chapter: skir.DataValue.unfilled,
      second: skir.DataValue.wrapStringValue("remote"),
    );
    final harness = await _mount(tester, current);
    await expectLater(
      harness.ref.editPagesChapter(pages, "", "group"),
      throwsA(
        isA<ApiException>().having((error) => error.code, "conflict code", 409),
      ),
    );
    expect(harness.intents, isEmpty);
    expect(
      harness.ref
          .readAuthoringSession()
          .state
          .draft!
          .resource(_page)!
          .authoredField("chapter"),
      skir.DataValue.unfilled,
    );
  });
}

Future<_Harness> _mount(
  WidgetTester tester,
  AuthoringSessionState state,
) async {
  final harness = _Harness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        organizationIdProvider.overrideWithValue(_organization),
        realmIdProvider.overrideWithValue(_realm),
        ...authoringSessionMockOverrides(
          initial: state,
          onApply: (intents) async => harness.intents.addAll(intents),
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          harness.ref = ref;
          ref
            ..watch(authoringSessionProvider(_organization, _realm))
            ..watch(selectionProvider)
            ..watch(selectedProvider);
          return const SizedBox();
        },
      ),
    ),
  );
  return harness;
}

class _Harness {
  late WidgetRef ref;
  final intents = <skir.EditIntent>[];
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

skir.ValueLocation _field(skir.ResourceId id) => skir.ValueLocation(
  resource: id,
  path: skir.ValuePath(
    segments: [skir.PathSegment.createField(name: "chapter")],
  ),
);
final _page = skir.ResourceId(value: "page:test");
final _second = skir.ResourceId(value: "page:second");
final _generation = skir.CatalogGeneration(value: "catalog:page");
final _organization = skir.recordId("organization:test");
final _realm = skir.recordId("realm:test");

final _book = skir.ResourceId(value: "book:test");
