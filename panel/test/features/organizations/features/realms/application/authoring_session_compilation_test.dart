import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/compiled_content.dart"
    as compiled_wire;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/provider_test_utils.dart";

const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.snapshot.get";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.library.authoring.changed";
const _compiledSubject =
    "service.from.realm1.organization.org1.realm.compiled.content.watch";

void main() {
  test("direct page changes update an acquired document", () async {
    final nats = FakeNatsClient();
    var snapshotSequence = 1;
    var snapshotRequests = 0;
    var pageName = "Initial";
    final snapshotScopes = <List<wire.AuthoringSnapshotScope_kind>>[];
    wire.PageCompileStatus compileStatus = wire.PageCompileStatus.notCompiled;
    nats.registerHandler(_snapshotSubject, (payload) {
      final request = wire.GetAuthoringSnapshotRequest.serializer.fromBytes(
        payload,
      );
      snapshotScopes.add(request.scopes.map((scope) => scope.kind).toList());
      snapshotRequests++;
      if (snapshotRequests == 4) {
        pageName = "During refresh";
        nats.emitMessageOnSubject(
          _eventSubject,
          wire.AuthoringChanged.serializer.toBytes(
            wire.AuthoringChanged(
              sequence: 3,
              batchId: "during-compile-refresh",
              changes: [
                wire.AuthoringResourceChange.wrapUpsertPage(
                  _wirePage("During refresh"),
                ),
              ],
              indirectlyAffectedResources: const [],
            ),
          ),
        );
      }
      return wire.GetAuthoringSnapshotResponse.serializer.toBytes(
        wire.GetAuthoringSnapshotResponse.createSuccess(
          sequence: snapshotSequence,
          slices: [
            for (final scope in request.scopes)
              switch (scope) {
                wire.AuthoringSnapshotScope.library_ =>
                  wire.AuthoringSnapshotSlice.createLibrary(
                    books: [_wireBook()],
                    tags: const [],
                  ),
                wire.AuthoringSnapshotScope_bookWrapper() =>
                  wire.AuthoringSnapshotSlice.createBook(
                    bookId: _book,
                    book: _wireBook(),
                    pages: [_wirePage(pageName)],
                  ),
                wire.AuthoringSnapshotScope_pageWrapper() =>
                  wire.AuthoringSnapshotSlice.createPage(
                    pageId: _page,
                    document: wire.PageDocument(
                      page: _wirePage(pageName),
                      elements: const [],
                      references: const [],
                      crossPageTargets: const [],
                      crossPageSources: const [],
                      diagnostics: const [],
                      compileStatus: compileStatus,
                    ),
                  ),
                wire.AuthoringSnapshotScope_unknown() => throw StateError(
                  "Unknown authoring scope",
                ),
              },
          ],
        ),
      );
    });
    final container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_org),
        realmIdProvider.overrideWithValue(_realm),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );

    final provider = authoringSessionProvider(_org, _realm);
    final subscription = container.listen(provider, (_, _) {});
    final libraryLease = container.read(provider.notifier).acquireLibrary();
    await libraryLease.ready;
    final bookLease = container.read(provider.notifier).acquireBook(_book);
    await bookLease.ready;
    final pageLease = container.read(provider.notifier).acquirePage(_page);
    await pageLease.ready;
    nats.emitMessageOnSubject(
      _eventSubject,
      wire.AuthoringChanged.serializer.toBytes(
        wire.AuthoringChanged(
          sequence: 2,
          batchId: "page-update",
          changes: [
            wire.AuthoringResourceChange.wrapUpsertPage(_wirePage("Updated")),
          ],
          indirectlyAffectedResources: const [],
        ),
      ),
    );
    await waitForProvider(
      container,
      provider,
      (state) => state.sequence == 2,
      description: "direct page change sequence 2",
    );

    expect(container.read(provider).pages[_page]?.name, "Updated");
    expect(container.read(provider).documents[_page]?.page.name, "Updated");

    snapshotSequence = 4;
    compileStatus = wire.PageCompileStatus.createBlocked(
      lastActiveManifestId: null,
      diagnosticCount: 1,
    );
    nats.emitMessageOnSubject(
      _compiledSubject,
      compiled_wire.WatchCompiledContentResponse.serializer.toBytes(
        compiled_wire.WatchCompiledContentResponse.createBlocked(),
      ),
    );
    await waitForProvider(
      container,
      provider,
      (state) =>
          state.documents[_page]?.compileStatus
              is wire.PageCompileStatus_blockedWrapper,
      description: "blocked page compile status",
    );
    await waitForProvider(
      container,
      provider,
      (state) => state.sequence == 4,
      description: "full recovery sequence 4",
    );
    expect(container.read(provider).pages[_page]?.name, "During refresh");
    expect(snapshotRequests, 4);
    expect(snapshotScopes.last, [
      wire.AuthoringSnapshotScope_kind.libraryConst,
      wire.AuthoringSnapshotScope_kind.bookWrapper,
      wire.AuthoringSnapshotScope_kind.pageWrapper,
    ]);
    final pageOnlyRequestBytes = wire.GetAuthoringSnapshotRequest.serializer
        .toBytes(
          wire.GetAuthoringSnapshotRequest(
            scopes: [wire.AuthoringSnapshotScope.createPage(pageId: _page)],
          ),
        )
        .length;
    final compilationRequestBytes = nats.requests
        .where((request) => request.subject == _snapshotSubject)
        .last
        .payload
        .length;
    expect(compilationRequestBytes, greaterThan(pageOnlyRequestBytes));

    pageLease.release();
    bookLease.release();
    libraryLease.release();
    subscription.close();
    container.dispose();
    await nats.dispose();
  });
}

final _org = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _book = recordId("book:book1");
final _page = recordId("page:page1");

wire.Page _wirePage(String name) => wire.Page(
  id: _page,
  book: _book,
  name: name,
  kind: skir.PageKindRef(id: skir.PageKindId(value: "test"), revision: 1),
  chapter: "",
  priority: 0,
);

wire.Book _wireBook() => wire.Book(
  id: _book,
  title: "Book",
  icon: "mdi:book",
  color: skir.Color(argb: 0xFF000000.toSigned(32)),
  tags: const [],
);
