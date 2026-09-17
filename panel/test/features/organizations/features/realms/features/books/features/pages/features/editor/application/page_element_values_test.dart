import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.snapshot.get";
const _batchSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.batch.apply";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.library.authoring.changed";
const _typeId = "0123456789abcdef0123456789abcdef";

void main() {
  test(
    "duplication submits one batch with a complete identity rewrite map",
    () async {
      final harness = await _Harness.create();
      skir.ApplyAuthoringBatchRequest? submitted;
      harness.nats.registerHandler(_batchSubject, (bytes) {
        submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
        return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
          skir.ApplyAuthoringBatchResponse.createApplied(
            sequence: 2,
            batchId: submitted!.batchId,
            changes: const [],
            indirectlyAffectedResources: const [],
          ),
        );
      });
      final first = harness._wireElement();
      final second = skir.PageElement(
        id: recordId("element:second"),
        page: first.page,
        elementType: first.elementType,
        schemaRevision: first.schemaRevision,
        name: "Second",
        value: first.value,
        placement: first.placement,
      );
      final copies = {
        first: (
          id: newResourceId(AuthoringResource.element),
          placement: first.placement,
        ),
        second: (
          id: newResourceId(AuthoringResource.element),
          placement: second.placement,
        ),
      };

      await harness.container
          .read(authoringSessionProvider(_organization, _realm).notifier)
          .duplicateElements(copies);
      final operations = submitted!.operations
          .cast<skir.AuthoringOperation_duplicateElementWrapper>()
          .toList();
      expect(operations, hasLength(2));
      for (final operation in operations) {
        expect(
          operation.value.referenceRewrites.map((rewrite) => rewrite.source),
          [first.id, second.id],
        );
        expect(
          operation.value.referenceRewrites.map((rewrite) => rewrite.target),
          copies.values.map((copy) => copy.id),
        );
        expect(operation.value.newId.id, matches(RegExp(r"^[a-z0-9]{20}$")));
      }
      await harness.dispose();
    },
  );

  test(
    "graph creation uses the supplied anchor and clears existing entries",
    () async {
      final harness = await _Harness.create();
      skir.ApplyAuthoringBatchRequest? submitted;
      harness.nats.registerHandler(_batchSubject, (bytes) {
        submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
        return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
          skir.ApplyAuthoringBatchResponse.createApplied(
            sequence: 2,
            batchId: submitted!.batchId,
            changes: const [],
            indirectlyAffectedResources: const [],
          ),
        );
      });

      await harness.notifier.createEntries(
        [harness.elementDefinition],
        EntryPlacementKind.graph,
        preferredGraphAnchor: const Offset(10, 10),
      );

      final operation =
          submitted!.operations.single
              as skir.AuthoringOperation_createElementWrapper;
      final placement = switch (operation.value.element.placement) {
        skir.ElementPlacement_graphWrapper(:final value) => value,
        _ => fail("Created element did not use graph placement"),
      };
      expect(
        (placement.x, placement.y, placement.width, placement.height),
        (8, 10, 4, 1),
      );
      await harness.dispose();
    },
  );

  test(
    "graph batch creation preserves one empty cell between entries",
    () async {
      final harness = await _Harness.create();
      skir.ApplyAuthoringBatchRequest? submitted;
      harness.nats.registerHandler(_batchSubject, (bytes) {
        submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
        return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
          skir.ApplyAuthoringBatchResponse.createApplied(
            sequence: 2,
            batchId: submitted!.batchId,
            changes: const [],
            indirectlyAffectedResources: const [],
          ),
        );
      });

      await harness.notifier.createEntries(
        [harness.elementDefinition, harness.elementDefinition],
        EntryPlacementKind.graph,
        preferredGraphAnchor: const Offset(10, 10),
      );

      final placements = [
        for (final operation
            in submitted!.operations
                .cast<skir.AuthoringOperation_createElementWrapper>())
          switch (operation.value.element.placement) {
            skir.ElementPlacement_graphWrapper(:final value) => value,
            _ => fail("Created element did not use graph placement"),
          },
      ];
      expect(placements[1].y, placements[0].y + placements[0].height + 1);
      await harness.dispose();
    },
  );

  test("graph duplication places the copy beside its source", () async {
    final harness = await _Harness.create();
    skir.ApplyAuthoringBatchRequest? submitted;
    harness.nats.registerHandler(_batchSubject, (bytes) {
      submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createApplied(
          sequence: 2,
          batchId: submitted!.batchId,
          changes: const [],
          indirectlyAffectedResources: const [],
        ),
      );
    });

    await harness.notifier.duplicateAll([_element.id]);

    final operation =
        submitted!.operations.single
            as skir.AuthoringOperation_duplicateElementWrapper;
    final placement = switch (operation.value.placement) {
      skir.ElementPlacement_graphWrapper(:final value) => value,
      _ => fail("Duplicated element did not use graph placement"),
    };
    expect(
      (placement.x, placement.y, placement.width, placement.height),
      (5, 0, 4, 1),
    );
    await harness.dispose();
  });

  test("page movement patches page and placement atomically", () async {
    final harness = await _Harness.create();
    skir.ApplyAuthoringBatchRequest? submitted;
    harness.nats.registerHandler(_batchSubject, (bytes) {
      submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createApplied(
          sequence: 2,
          batchId: submitted!.batchId,
          changes: const [],
          indirectlyAffectedResources: const [],
        ),
      );
    });
    final element = harness._wireElement();
    final target = recordId("page:target");
    final placement = skir.ElementPlacement.createGraph(
      x: 7,
      y: 8,
      width: 4,
      height: 1,
    );

    await harness.container
        .read(authoringSessionProvider(_organization, _realm).notifier)
        .moveElementsToPage([(element, placement)], target);

    final operation =
        submitted!.operations.single
            as skir.AuthoringOperation_patchElementWrapper;
    expect(operation.value.page?.expected, element.page);
    expect(operation.value.page?.value, target);
    expect(operation.value.placement?.expected, element.placement);
    expect(operation.value.placement?.value, placement);
    await harness.dispose();
  });

  test("cross page movement clears target graph content", () async {
    final harness = await _Harness.create()
      ..targetPageExists = true;
    skir.ApplyAuthoringBatchRequest? submitted;
    harness.nats.registerHandler(_batchSubject, (bytes) {
      submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createApplied(
          sequence: 2,
          batchId: submitted!.batchId,
          changes: const [],
          indirectlyAffectedResources: const [],
        ),
      );
    });

    await harness.notifier.moveEntriesToPage([_element.id], _targetPage.id);

    final operation =
        submitted!.operations.single
            as skir.AuthoringOperation_patchElementWrapper;
    final placement = switch (operation.value.placement?.value) {
      skir.ElementPlacement_graphWrapper(:final value) => value,
      _ => fail("Moved element did not use graph placement"),
    };
    expect(operation.value.page?.value, _targetPage);
    expect((placement.x, placement.y), (0, 2));
    await harness.dispose();
  });

  test("invalid element update restores the session value", () async {
    final harness = await _Harness.create();
    harness.respondWithInvalid();
    await expectLater(
      harness.notifier.updateEntryFieldValue(
        _element.id,
        DataPath.root.field("title"),
        const StringValue("Rejected"),
      ),
      throwsA(isA<ApiException>()),
    );

    expect(harness.value.fields["title"], const StringValue("Initial"));

    await harness.dispose();
  });

  test(
    "entry and health remain available after the page listener is released",
    () async {
      final harness = await _Harness.create();
      final sessionOwner = harness.container.listen(
        authoringSessionProvider(_organization, _realm),
        (_, _) {},
      );
      final indexProvider = realmEntryIndexProvider(_organization, _realm);
      final indexOwner = harness.container.listen(indexProvider, (_, _) {});

      harness.closePageElements();
      await pumpEventQueue();

      final cached = harness.container.read(indexProvider).requireValue;
      expect(cached[_element.id]?.pageId, _page.id);
      expect(
        harness.container.read(
          pageDocumentHealthProvider(_organization, _realm, _page),
        ),
        isNotNull,
      );

      indexOwner.close();
      sessionOwner.close();
      await harness.dispose();
    },
  );

  test("page deletion clears derived entries and health", () async {
    final harness = await _Harness.create();
    final indexProvider = realmEntryIndexProvider(_organization, _realm);
    final indexOwner = harness.container.listen(indexProvider, (_, _) {});
    harness
      ..closePageElements()
      ..emitPageRemoved();
    await pumpEventQueue();

    expect(harness.container.read(indexProvider).requireValue, isEmpty);
    expect(
      harness.container.read(
        pageDocumentHealthProvider(_organization, _realm, _page),
      ),
      isNull,
    );

    indexOwner.close();
    await harness.dispose();
  });

  test("removed retained entry fails before mutation submission", () async {
    final harness = await _Harness.create();
    final sessionOwner = harness.container.listen(
      authoringSessionProvider(_organization, _realm),
      (_, _) {},
    );
    final entry = entryProvider(_element.id);
    final entryOwner = harness.container.listen(entry, (_, _) {});
    await harness.container.read(entry.future);
    harness.closePageElements();

    await pumpEventQueue();
    harness.pageExists = false;

    await expectLater(
      harness.container
          .read(entry.notifier)
          .updateFieldValue(
            DataPath.root.field("title"),
            const StringValue("Local"),
          ),
      throwsA(isA<ApiException>().having((error) => error.code, "code", 404)),
    );
    expect(
      harness.nats.requests.where(
        (request) => request.subject == _batchSubject,
      ),
      isEmpty,
    );

    entryOwner.close();
    sessionOwner.close();
    await harness.dispose();
  });

  test("catalog replacement redecodes retained page documents", () async {
    final harness = await _Harness.create();

    harness.replaceCatalog(elementName: "Replacement");
    await pumpEventQueue();

    expect(harness.elementDefinition.name, "Replacement");

    await harness.dispose();
  });

  test(
    "catalog invalidation retains definitions required by documents",
    () async {
      final source = _TrackingCatalogSource();
      final harness = await _Harness.create(catalogSource: source);
      final documentsProvider = decodedRealmDocumentsProvider(
        _organization,
        _realm,
      );
      final documentsOwner = harness.container.listen(
        documentsProvider,
        (_, _) {},
      );
      harness.closePageElements();
      await pumpEventQueue();

      final requestsBeforeInvalidation = source.requests.length;

      source.invalidate();
      await pumpEventQueue();

      expect(source.requests.length, greaterThan(requestsBeforeInvalidation));
      expect(source.requests.last.types, {_type});
      expect(
        harness.container.read(documentsProvider).requireValue[_page.id],
        hasLength(1),
      );

      documentsOwner.close();
      await harness.dispose();
      await source.close();
    },
  );

  test(
    "realm switch hides old documents while the new catalog is pending",
    () async {
      final harness = await _Harness.create();
      final documentsProvider = decodedRealmDocumentsProvider(
        _organization,
        _realm,
      );
      final documentsOwner = harness.container.listen(
        documentsProvider,
        (_, _) {},
      );
      harness.closePageElements();
      await pumpEventQueue();
      expect(harness.container.read(documentsProvider).hasValue, isTrue);

      harness.switchRealm(_secondRealm);
      await pumpEventQueue();

      expect(harness.container.read(documentsProvider).isLoading, isTrue);
      expect(
        harness.nats.subscriptionSubjects.where(
          (subject) => subject.contains("realm1"),
        ),
        isEmpty,
      );

      documentsOwner.close();
      await harness.dispose();
    },
  );

  test("realm switch aborts a retained edit before submission", () async {
    final harness = await _Harness.create();
    final sessionOwner = harness.container.listen(
      authoringSessionProvider(_organization, _realm),
      (_, _) {},
    );
    final entry = entryProvider(_element.id);
    final entryOwner = harness.container.listen(entry, (_, _) {});
    await harness.container.read(entry.future);
    harness.closePageElements();

    await pumpEventQueue();
    final snapshot = Completer<Uint8List>();
    harness.nats.registerHandler(_snapshotSubject, (_) => snapshot.future);

    final edit = harness.container
        .read(entry.notifier)
        .updateFieldValue(
          DataPath.root.field("title"),
          const StringValue("Local"),
        );
    final rejected = expectLater(
      edit,
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, "code", 409)
            .having(
              (error) => error.message,
              "message",
              "The selected realm changed while the page was loading",
            ),
      ),
    );
    await _waitFor(
      () =>
          harness.nats.requests
              .where((request) => request.subject == _snapshotSubject)
              .length ==
          2,
    );

    harness.switchRealm(_secondRealm);
    snapshot.complete(harness._snapshot());
    await rejected;
    expect(
      harness.nats.requests.where(
        (request) => request.subject == _batchSubject,
      ),
      isEmpty,
    );

    entryOwner.close();
    sessionOwner.close();
    await harness.dispose();
  });

  test("realm switch aborts an edit waiting for the catalog", () async {
    final harness = await _Harness.create();
    final sessionOwner = harness.container.listen(
      authoringSessionProvider(_organization, _realm),
      (_, _) {},
    );
    final entry = entryProvider(_element.id);
    final entryOwner = harness.container.listen(entry, (_, _) {});
    await harness.container.read(entry.future);
    harness.closePageElements();

    await pumpEventQueue();
    final snapshot = Completer<Uint8List>();
    harness.nats.registerHandler(_snapshotSubject, (_) => snapshot.future);

    final edit = harness.container
        .read(entry.notifier)
        .updateFieldValue(
          DataPath.root.field("title"),
          const StringValue("Local"),
        );
    final rejected = expectLater(
      edit,
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, "code", 409)
            .having(
              (error) => error.message,
              "message",
              "The selected realm changed while the page was loading",
            ),
      ),
    );
    await _waitFor(
      () =>
          harness.nats.requests
              .where((request) => request.subject == _snapshotSubject)
              .length ==
          2,
    );
    harness.catalogStates.add(const RealmEditorCatalogState.loading());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    snapshot.complete(harness._snapshot());

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      harness.nats.requests.where(
        (request) => request.subject == _batchSubject,
      ),
      isEmpty,
    );

    harness.switchRealm(_secondRealm);
    await rejected;
    expect(
      harness.nats.requests.where(
        (request) => request.subject == _batchSubject,
      ),
      isEmpty,
    );

    entryOwner.close();
    sessionOwner.close();
    await harness.dispose();
  });

  test("retained entry reacquires its page before editing", () async {
    final harness = await _Harness.create();
    final sessionOwner = harness.container.listen(
      authoringSessionProvider(_organization, _realm),
      (_, _) {},
    );
    final entry = entryProvider(_element.id);
    final entryOwner = harness.container.listen(entry, (_, _) {});
    await harness.container.read(entry.future);
    harness.closePageElements();

    await pumpEventQueue();
    harness.title = "Fresh";
    skir.ApplyAuthoringBatchRequest? submitted;
    harness.nats.registerHandler(_batchSubject, (bytes) {
      submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createInvalid(diagnostics: const []),
      );
    });

    await expectLater(
      harness.container
          .read(entry.notifier)
          .updateFieldValue(
            DataPath.root.field("title"),
            const StringValue("Local"),
          ),
      throwsA(isA<ApiException>()),
    );

    final operation =
        submitted!.operations.single
            as skir.AuthoringOperation_patchElementWrapper;
    final expected = SkirEditorCodec(
      TypeRegistry(bootstrapTypeCatalog(harness.catalog.catalog.definitions)),
    ).decodeValue(operation.value.valueMutations.single.expected).valueOrNull;
    expect(expected, const StringValue("Fresh"));
    expect(
      harness.nats.requests.where(
        (request) => request.subject == _snapshotSubject,
      ),
      hasLength(3),
    );

    entryOwner.close();
    sessionOwner.close();
    await harness.dispose();
  });

  test("rejected field update preserves a concurrent remote value", () async {
    final harness = await _Harness.create();
    harness.respondWithInvalid(
      onRequest: () {
        harness.emitRemote(title: "Remote");
      },
    );

    await expectLater(
      harness.notifier.updateEntryFieldValue(
        _element.id,
        DataPath.root.field("title"),
        const StringValue("Local"),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          "message",
          contains("Rejected"),
        ),
      ),
    );

    expect(harness.value.fields["title"], const StringValue("Remote"));

    await harness.dispose();
  });

  test(
    "placement conflict preserves local intent and refreshed canonical value",
    () async {
      final harness = await _Harness.create();
      harness.nats.registerHandler(_batchSubject, (_) {
        harness
          ..sequence = 2
          ..x = 8;
        return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
          skir.ApplyAuthoringBatchResponse.createConflict(conflicts: const []),
        );
      });

      await expectLater(
        harness.notifier.moveAll([(_element.id, 4, 0)]),
        throwsA(isA<ApiException>()),
      );

      expect(harness.placement.x, 8);
      expect(harness.projectedPlacement.x, 4);
      final draft = harness.container
          .read(localWorkControllerProvider)
          .resources
          .values
          .single
          .source;
      expect(
        elementPlacementPath
            .field("x")
            .read(draft.document.confirmedValue)
            .valueOrNull,
        IntegerValue(BigInt.from(8)),
      );
      expect(draft.hasWork, isTrue);

      await harness.dispose();
    },
  );
}

final class _Harness {
  _Harness._({RealmEditorCatalogSource? catalogSource}) {
    nats.registerHandler(_snapshotSubject, (_) => _snapshot());
    container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_organization),
        realmIdProvider.overrideWith((ref) => activeRealm),
        realmConnectionProvider.overrideWith(
          (ref) => Stream.value(RealmConnectionState.online),
        ),
        if (catalogSource == null)
          realmEditorCatalogProvider.overrideWith((ref) {
            ref.watch(realmIdProvider);
            return catalogStates.stream;
          }),
        realmEditorCatalogSourceProvider.overrideWithValue(
          catalogSource ?? _SnapshotCatalogSource(() => catalog),
        ),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
    provider = pageElementsProvider(_organization, _realm, _page.id);
    subscription = container.listen(provider, (_, _) {});
  }

  static Future<_Harness> create({
    RealmEditorCatalogSource? catalogSource,
  }) async {
    final harness = _Harness._(catalogSource: catalogSource);
    final page = harness.container.read(harness.provider.future);
    if (catalogSource == null) {
      await pumpEventQueue();
      harness.catalogStates.add(RealmEditorCatalogState.ready(harness.catalog));
    }
    await page;
    return harness;
  }

  final FakeNatsClient nats = FakeNatsClient();
  final StreamController<RealmEditorCatalogState> catalogStates =
      StreamController<RealmEditorCatalogState>.broadcast();
  RealmEditorCatalogSnapshot catalog = _catalog();
  late final ProviderContainer container;
  late final PageElementsProvider provider;
  late final ProviderSubscription<AsyncValue<List<PageElement>>> subscription;
  skir.RecordId activeRealm = _realm;
  bool _pageElementsClosed = false;
  int sequence = 1;
  bool pageExists = true;
  bool targetPageExists = false;
  String title = "Initial";
  int x = 0;

  PageElements get notifier => container.read(provider.notifier);

  RecordValue get value {
    final element = container.read(provider).requireValue.single;
    final entry = (element as PageElementEntry).entry as DefinitionPageEntry;
    return entry.definition.data;
  }

  EntryPlacement get placement {
    final element = container.read(provider).requireValue.single;
    final entry = (element as PageElementEntry).entry as DefinitionPageEntry;
    return entry.definition.placement;
  }

  EntryPlacement get projectedPlacement {
    final element = container
        .read(projectedPageElementsProvider(_organization, _realm, _page.id))
        .requireValue
        .single;
    final entry = (element as PageElementEntry).entry as DefinitionPageEntry;
    return entry.definition.placement;
  }

  ElementDefinition get elementDefinition {
    final element = container.read(provider).requireValue.single;
    final entry = (element as PageElementEntry).entry as DefinitionPageEntry;
    return entry.definition.elementDefinition;
  }

  void closePageElements() {
    if (_pageElementsClosed) return;
    _pageElementsClosed = true;
    subscription.close();
  }

  void replaceCatalog({required String elementName}) {
    catalog = _catalog(elementName: elementName);
    catalogStates.add(RealmEditorCatalogState.ready(catalog));
  }

  void switchRealm(skir.RecordId realm) {
    activeRealm = realm;
    container.invalidate(realmIdProvider);
  }

  void respondWithInvalid({void Function()? onRequest}) {
    nats.registerHandler(_batchSubject, (_) {
      onRequest?.call();
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createInvalid(
          diagnostics: [
            skir.AuthoringDiagnostic(
              code: "invalid",
              message: "Rejected",
              resource: null,
              path: null,
            ),
          ],
        ),
      );
    });
  }

  void emitRemote({required String title}) {
    sequence++;
    this.title = title;
    nats.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(
        skir.AuthoringChanged(
          sequence: sequence,
          batchId: "remote-$sequence",
          changes: [
            skir.AuthoringResourceChange.wrapUpsertElement(_wireElement()),
          ],
          indirectlyAffectedResources: const [],
        ),
      ),
    );
  }

  void emitPageRemoved() {
    sequence++;
    nats.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(
        skir.AuthoringChanged(
          sequence: sequence,
          batchId: "remove-page-$sequence",
          changes: [skir.AuthoringResourceChange.wrapRemovePage(_page)],
          indirectlyAffectedResources: const [],
        ),
      ),
    );
  }

  Uint8List _snapshot() => skir.GetAuthoringSnapshotResponse.serializer.toBytes(
    skir.GetAuthoringSnapshotResponse.createSuccess(
      sequence: sequence,
      slices: [
        skir.AuthoringSnapshotSlice.createPage(
          pageId: _page,
          document: pageExists
              ? skir.PageDocument(
                  page: _wirePage,
                  elements: [_wireElement()],
                  references: const [],
                  crossPageTargets: const [],
                  crossPageSources: const [],
                  diagnostics: const [],
                  compileStatus: skir.PageCompileStatus.notCompiled,
                )
              : null,
        ),
        if (targetPageExists)
          skir.AuthoringSnapshotSlice.createPage(
            pageId: _targetPage,
            document: skir.PageDocument(
              page: _wireTargetPage,
              elements: [_wireTargetElement()],
              references: const [],
              crossPageTargets: const [],
              crossPageSources: const [],
              diagnostics: const [],
              compileStatus: skir.PageCompileStatus.notCompiled,
            ),
          ),
      ],
    ),
  );

  skir.PageElement _wireElement() {
    final codec = SkirEditorCodec(
      TypeRegistry(bootstrapTypeCatalog(catalog.catalog.definitions)),
    );
    final value = RecordValue({"title": StringValue(title)});
    return skir.PageElement(
      id: _element,
      page: _page,
      elementType: _typeId,
      schemaRevision: 1,
      name: "Element",
      value: codec.encodeValue(value).valueOrNull!,
      placement: skir.ElementPlacement.createGraph(
        x: x,
        y: 0,
        width: 4,
        height: 1,
      ),
    );
  }

  skir.PageElement _wireTargetElement() {
    final source = _wireElement();
    return skir.PageElement(
      id: recordId("element:target"),
      page: _targetPage,
      elementType: source.elementType,
      schemaRevision: source.schemaRevision,
      name: "Target Element",
      value: source.value,
      placement: skir.ElementPlacement.createGraph(
        x: 0,
        y: 0,
        width: 4,
        height: 1,
      ),
    );
  }

  Future<void> dispose() async {
    closePageElements();
    container.dispose();
    await catalogStates.close();
    await nats.dispose();
  }
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail("Condition was not reached");
}

final _organization = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _secondRealm = recordId("service:realm2");
final _book = recordId("book:book1");
final _page = recordId("page:page1");
final _targetPage = recordId("page:target");
final _element = recordId("element:element1");
final _type = ResolvedTypeRef(id: DeclaredTypeId(_typeId), revision: 1);

final _wirePage = skir.Page(
  id: _page,
  book: _book,
  name: "Page",
  kind: skir.PageKindRef(id: skir.PageKindId(value: "test"), revision: 1),
  chapter: "",
  priority: 0,
);

final _wireTargetPage = skir.Page(
  id: _targetPage,
  book: _book,
  name: "Target Page",
  kind: skir.PageKindRef(id: skir.PageKindId(value: "test"), revision: 1),
  chapter: "",
  priority: 1,
);

RealmEditorCatalogSnapshot _catalog({String elementName = "Element"}) =>
    RealmEditorCatalogSnapshot(
      catalog: TypeCatalog([
        TypeDefinition(
          id: _type,
          kind: NominalTypeKind.concrete,
          representation: RecordType(
            fields: {
              "title": const TypeField(name: "title", type: StringType()),
            },
          ),
        ),
      ]),
      generation: const CatalogGeneration("1"),
      elements: {
        _typeId: RealmElementCatalogEntry(
          originArtifactId: "test",
          sourcePart: "test",
          definition: DiscoveredElementDefinition(
            id: _typeId,
            type: _type,
            name: elementName,
            description: "Test element",
            icon: const IconValue.iconify("mdi:test-tube"),
            color: Colors.blue,
            availability: const ElementAvailability.always(),
          ),
          eligible: true,
          available: true,
        ),
      },
    );

final class _TrackingCatalogSource implements RealmEditorCatalogSource {
  final List<RealmEditorCatalogRequest> requests = [];
  final StreamController<RealmEditorCatalogWatchEvent> events =
      StreamController<RealmEditorCatalogWatchEvent>();
  int _generation = 1;

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async {
    requests.add(request);
    return RealmEditorCatalogFetchResult.fetched(
      _catalog().copyWith(generation: CatalogGeneration("$_generation")),
    );
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => events.stream;

  void invalidate() {
    _generation++;
    events.add(
      RealmEditorCatalogWatchEvent.invalidated(
        CatalogGeneration("$_generation"),
      ),
    );
  }

  Future<void> close() => events.close();
}

final class _SnapshotCatalogSource implements RealmEditorCatalogSource {
  const _SnapshotCatalogSource(this.snapshot);
  final RealmEditorCatalogSnapshot Function() snapshot;

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async => RealmEditorCatalogFetchResult.fetched(snapshot());

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => const Stream.empty();
}
