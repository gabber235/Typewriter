import "dart:typed_data";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:skir_client/skir_client.dart" show Serializer;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/path.dart"
    as wire_path;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    show TypedValue;
import "package:typewriter_panel/typewriter_panel.dart";

part "page_elements.freezed.dart";
part "page_elements.g.dart";

final class CachedPageEntry {
  const CachedPageEntry({required this.pageId, required this.definition});

  final String pageId;
  final EntryDefinition definition;
}

final class PageDocumentHealth {
  const PageDocumentHealth({
    required this.diagnostics,
    required this.compileBlocked,
    required this.activeManifestId,
  });

  final List<String> diagnostics;
  final bool compileBlocked;
  final String? activeManifestId;
}

@Riverpod(keepAlive: true)
class PageDocumentHealthCache extends _$PageDocumentHealthCache {
  @override
  Map<String, PageDocumentHealth> build() => const {};

  void put(String pageId, PageDocumentHealth health) {
    state = {...state, pageId: health};
  }
}

@Riverpod(keepAlive: true)
class PageEntryCache extends _$PageEntryCache {
  @override
  Map<String, CachedPageEntry> build() => const {};

  void replacePage(String pageId, List<PageElement> elements) {
    state = {
      for (final entry in state.entries)
        if (entry.value.pageId != pageId) entry.key: entry.value,
      for (final element in elements)
        if (element case PageElementEntry(
          entry: DefinitionPageEntry(:final definition),
        ))
          definition.id: CachedPageEntry(
            pageId: pageId,
            definition: definition,
          ),
    };
  }
}

@riverpod
Stream<int> pageDocumentInvalidations(Ref ref, String pageId) async* {
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (realmId == null || organizationId == null) {
    yield 0;
    return;
  }
  final address = RealmServiceAddress(
    organizationId: organizationId,
    realmId: realmId,
  );
  final request = skir.WatchPageDocumentsRequest(
    pageIds: [recordId("page:$pageId")],
  );
  yield* ref.watchRequest(
    subject: address.request("page.document.watch.v2"),
    listenSubject: address.event("page.document.watch.v2"),
    requestBytes: skir.WatchPageDocumentsRequest.serializer.toBytes(request),
    serializer: skir.WatchPageDocumentsResponse.serializer,
    transformer: (previous, response) => switch (response) {
      _ when response == skir.WatchPageDocumentsResponse.initial =>
        previous ?? 0,
      skir.WatchPageDocumentsResponse_invalidatedWrapper(:final value)
          when value.revision > (previous ?? 0) =>
        value.revision,
      skir.WatchPageDocumentsResponse_invalidatedWrapper() => previous ?? 0,
      skir.WatchPageDocumentsResponse_invalidRequestWrapper(:final value) =>
        throw ApiException.badRequest(value.diagnostics.join("; ")),
      skir.WatchPageDocumentsResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.WatchPageDocumentsResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
      _ => throw ApiException.unknownResponseMessage(),
    },
  );
}

@riverpod
class PageElements extends _$PageElements {
  late String _currentPageId;

  @override
  Future<List<PageElement>> build(String pageId) async {
    _currentPageId = pageId;
    ref
      ..keepAlive()
      ..watch(organizationIdProvider)
      ..watch(realmIdProvider)
      ..watch(realmEditorCatalogProvider)
      ..watch(pageDocumentInvalidationsProvider(pageId));
    return _fetchElements();
  }

  Future<List<PageElement>> _fetchElements() async {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final catalogState = await ref.read(realmEditorCatalogProvider.future);
    final snapshot = catalogState.snapshot;
    if (snapshot == null) {
      throw ApiException.internalServerError();
    }
    final request = skir.GetPageDocumentRequest(
      pageId: recordId("page:$pageId"),
    );
    final response = await ref.requestSkir(
      RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      ).request("page.document.get.v2"),
      skir.GetPageDocumentRequest.serializer.toBytes(request),
      skir.GetPageDocumentResponse.serializer,
    );
    final document = switch (response) {
      skir.GetPageDocumentResponse_successWrapper(:final value) => value,
      skir.GetPageDocumentResponse_pageNotFoundWrapper() =>
        throw ApiException.notFound("Page"),
      skir.GetPageDocumentResponse_invalidRequestWrapper(:final value) =>
        throw ApiException.badRequest(value.diagnostics.join("; ")),
      skir.GetPageDocumentResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.GetPageDocumentResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
    };
    final elements = _decodePageElements(document, snapshot);
    ref
        .read(pageEntryCacheProvider.notifier)
        .replacePage(_currentPageId, elements);
    ref
        .read(pageDocumentHealthCacheProvider.notifier)
        .put(
          _currentPageId,
          PageDocumentHealth(
            diagnostics: document.diagnostics
                .map((value) => value.message)
                .toList(),
            compileBlocked:
                document.compileStatus is skir.PageCompileStatus_blockedWrapper,
            activeManifestId: switch (document.compileStatus) {
              skir.PageCompileStatus_activeWrapper(:final value) =>
                value.manifestId,
              skir.PageCompileStatus_blockedWrapper(:final value) =>
                value.lastActiveManifestId,
              _ => null,
            },
          ),
        );
    return elements;
  }

  void optimisticMoveAll(List<(String, int, int)> changed) {
    final data = state.requireValue;
    final map = <String, (int, int)>{
      for (final e in changed) e.$1: (e.$2, e.$3),
    };
    final newData = data.map((element) {
      final placement = map[element.id];
      if (placement == null) return element;
      return element.moveTo(placement.$1, placement.$2);
    }).toList();

    state = AsyncValue.data(newData);
  }

  void optimisticResizeAll(List<(String, int, int)> changed) {
    final data = state.requireValue;
    final map = <String, (int, int)>{
      for (final e in changed) e.$1: (e.$2, e.$3),
    };
    final newData = data.map((element) {
      final placement = map[element.id];
      if (placement == null) return element;
      return element.resizeTo(placement.$1, placement.$2);
    }).toList();

    state = AsyncValue.data(newData);
  }

  Future<void> moveAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    if (changed.isEmpty) return;
    final previous = state;
    optimisticMoveAll(changed);
    try {
      final revisions = _revisions(previous.requireValue);
      final request = skir.MoveGraphElementsRequest(
        batchId: _nextBatchId("move_graph"),
        moves: [
          for (final change in changed)
            skir.GraphElementMove(
              id: recordId("element:${change.$1}"),
              expectedRevision: revisions[change.$1]!,
              x: change.$2,
              y: change.$3,
            ),
        ],
      );
      await _submitBatch(
        "element.graph.move.v2",
        skir.MoveGraphElementsRequest.serializer.toBytes(request),
        skir.MoveGraphElementsResponse.serializer,
      );
      _incrementRevisions(changed.map((value) => value.$1).toSet());
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> resizeAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    if (changed.isEmpty) return;
    final previous = state;
    optimisticResizeAll(changed);
    try {
      final revisions = _revisions(previous.requireValue);
      final request = skir.ResizeGraphElementsRequest(
        batchId: _nextBatchId("resize_graph"),
        resizes: [
          for (final change in changed)
            skir.GraphElementResize(
              id: recordId("element:${change.$1}"),
              expectedRevision: revisions[change.$1]!,
              width: change.$2,
              height: change.$3,
            ),
        ],
      );
      await _submitBatch(
        "element.graph.resize.v2",
        skir.ResizeGraphElementsRequest.serializer.toBytes(request),
        skir.ResizeGraphElementsResponse.serializer,
      );
      _incrementRevisions(changed.map((value) => value.$1).toSet());
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  void optimisticCuesUpdate(List<(String, int, int)> changed) {
    final data = state.requireValue;
    final map = <String, (int, int)>{
      for (final entry in changed) entry.$1: (entry.$2, entry.$3),
    };
    final newData = data.map((element) {
      final frameRange = map[element.id];
      if (frameRange == null) return element;
      return element.updateCueTo(frameRange.$1, frameRange.$2);
    }).toList();

    state = AsyncValue.data(newData);
  }

  Future<void> updateCues(List<(String, int, int)> changed) async {
    state.ensureReady();
    if (changed.isEmpty) return;
    final previous = state;
    optimisticCuesUpdate(changed);
    try {
      final revisions = _revisions(previous.requireValue);
      final placements = {
        for (final element in previous.requireValue) element.id: element,
      };
      final request = skir.UpdateCueTimingsRequest(
        batchId: _nextBatchId("update_cues"),
        updates: [
          for (final change in changed)
            skir.CueTimingUpdate(
              id: recordId("element:${change.$1}"),
              expectedRevision: revisions[change.$1]!,
              placement: _updatedCuePlacement(
                placements[change.$1]!,
                change.$2,
                change.$3,
              ),
            ),
        ],
      );
      await _submitBatch(
        "element.cue.timing.update.v2",
        skir.UpdateCueTimingsRequest.serializer.toBytes(request),
        skir.UpdateCueTimingsResponse.serializer,
      );
      _incrementRevisions(changed.map((value) => value.$1).toSet());
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> updateCueFieldValue(
    String cueId,
    DataPath path,
    DataValue value,
  ) => _updateFieldValue(cueId, path, value);

  Future<void> updateEntryFieldValue(
    String entryId,
    DataPath path,
    DataValue value,
  ) => _updateFieldValue(entryId, path, value);

  Future<void> deleteAll(List<String> elementIds) async {
    state.ensureReady();
    if (elementIds.isEmpty) return;
    final previous = state;
    final elements = previous.requireValue;
    final revisions = _revisions(elements);
    final request = skir.DeleteElementsRequest(
      batchId: _nextBatchId("delete_elements"),
      deletions: [
        for (final elementId in elementIds)
          skir.ElementDeletion(
            id: recordId("element:$elementId"),
            expectedRevision: revisions[elementId]!,
          ),
      ],
    );
    try {
      await _submitBatch(
        "element.delete.v2",
        skir.DeleteElementsRequest.serializer.toBytes(request),
        skir.DeleteElementsResponse.serializer,
      );
      state = AsyncData([
        for (final element in elements)
          if (!elementIds.contains(element.id)) element,
      ]);
      ref
          .read(pageEntryCacheProvider.notifier)
          .replacePage(_currentPageId, state.requireValue);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<List<String>> createEntries(
    List<ElementDefinition> definitions,
    EntryPlacementKind placementKind,
  ) async {
    state.ensureReady();
    if (definitions.isEmpty) return const [];
    final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (snapshot == null) {
      throw ApiException.badRequest("The editor catalog is unavailable");
    }
    final registry = TypeRegistry(
      bootstrapTypeCatalog(snapshot.catalog.definitions),
    );
    final codec = SkirEditorCodec(registry);
    final ids = [
      for (var index = 0; index < definitions.length; index++) uuid.v4(),
    ];
    final values = [
      for (final definition in definitions)
        _initialElementValue(definition, registry, codec),
    ];
    final currentEntries = state.requireValue.whereType<PageElementEntry>();
    final graphY = currentEntries
        .map((entry) => entry.entry)
        .whereType<DefinitionPageEntry>()
        .map((entry) => entry.definition.placement.y + 1)
        .fold(0, (maximum, value) => value > maximum ? value : maximum);
    final request = skir.CreateElementsRequest(
      batchId: _nextBatchId("create_elements"),
      elements: [
        for (final indexed in definitions.indexed)
          skir.ElementCreate(
            id: recordId("element:${ids[indexed.$1]}"),
            page: recordId("page:$_currentPageId"),
            elementType: indexed.$2.typeId.uuid,
            schemaRevision: indexed.$2.rootType.revision,
            name: indexed.$2.name,
            value: values[indexed.$1],
            placement: switch (placementKind) {
              EntryPlacementKind.graph => skir.ElementPlacement.createGraphV1(
                x: 0,
                y: graphY + indexed.$1,
                width: 4,
                height: 1,
              ),
              EntryPlacementKind.timelineEntry =>
                skir.ElementPlacement.createTimelineEntryV1(
                  trackIndex: currentEntries.length + indexed.$1,
                ),
            },
          ),
      ],
    );
    await _submitBatch(
      "element.create.v2",
      skir.CreateElementsRequest.serializer.toBytes(request),
      skir.CreateElementsResponse.serializer,
    );
    state = AsyncData(await _fetchElements());
    return ids;
  }

  Future<List<String>> duplicateAll(List<String> elementIds) async {
    state.ensureReady();
    if (elementIds.isEmpty) return const [];
    final elements = state.requireValue;
    final entries = {
      for (final element in elements)
        if (element case PageElementEntry(
          entry: DefinitionPageEntry(:final definition),
        ))
          definition.id: definition,
    };
    final newIds = {for (final elementId in elementIds) elementId: uuid.v4()};
    final request = skir.DuplicateElementsRequest(
      batchId: _nextBatchId("duplicate_elements"),
      elements: [
        for (final elementId in elementIds)
          skir.ElementDuplicate(
            sourceId: recordId("element:$elementId"),
            expectedRevision: entries[elementId]!.revision,
            newId: recordId("element:${newIds[elementId]}"),
            page: recordId("page:$_currentPageId"),
            name: "${entries[elementId]!.name} Copy",
            placement: switch (entries[elementId]!.placement.kind) {
              EntryPlacementKind.graph => skir.ElementPlacement.createGraphV1(
                x: entries[elementId]!.placement.x + 1,
                y: entries[elementId]!.placement.y + 1,
                width: entries[elementId]!.placement.width,
                height: entries[elementId]!.placement.height,
              ),
              EntryPlacementKind.timelineEntry =>
                skir.ElementPlacement.createTimelineEntryV1(
                  trackIndex: entries[elementId]!.placement.x + 1,
                ),
            },
            referenceRewrites: const [],
          ),
      ],
    );
    await _submitBatch(
      "element.duplicate.v2",
      skir.DuplicateElementsRequest.serializer.toBytes(request),
      skir.DuplicateElementsResponse.serializer,
    );
    state = AsyncData(await _fetchElements());
    return [for (final elementId in elementIds) newIds[elementId]!];
  }

  Future<void> moveEntriesToPage(
    List<String> elementIds,
    String targetPageId,
  ) async {
    state.ensureReady();
    if (elementIds.isEmpty || targetPageId == _currentPageId) return;
    final entries = {
      for (final element in state.requireValue)
        if (element case PageElementEntry(
          entry: DefinitionPageEntry(:final definition),
        ))
          definition.id: definition,
    };
    final request = skir.MoveElementsToPagesRequest(
      batchId: _nextBatchId("move_elements_to_page"),
      moves: [
        for (final elementId in elementIds)
          skir.ElementPageMove(
            id: recordId("element:$elementId"),
            expectedRevision: entries[elementId]!.revision,
            page: recordId("page:$targetPageId"),
            placement: _entryPlacementToSkir(entries[elementId]!.placement),
          ),
      ],
    );
    await _submitBatch(
      "element.page.move.v2",
      skir.MoveElementsToPagesRequest.serializer.toBytes(request),
      skir.MoveElementsToPagesResponse.serializer,
    );
    ref
      ..invalidate(pageElementsProvider(_currentPageId))
      ..invalidate(pageElementsProvider(targetPageId));
  }

  Future<TypedMutationResult> commitElementValue(
    String elementId,
    EditorCommit commit,
  ) async {
    state.ensureReady();
    final previous = state;
    final elements = previous.requireValue;
    final current = elements.singleWhere((element) => element.id == elementId);
    final root = commit.rootValue;
    if (root is! RecordValue) {
      return TypedMutationResult.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Element values must be records",
        ),
      ]);
    }
    state = AsyncData([
      for (final element in elements)
        if (element.id == elementId)
          element.updateFieldValue(DataPath.root, root)
        else
          element,
    ]);
    final catalogState = ref.read(realmEditorCatalogProvider).value;
    final snapshot = catalogState?.snapshot;
    if (snapshot == null) {
      state = previous;
      return TypedMutationResult.unavailable([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "The Realm editor catalog is unavailable",
        ),
      ]);
    }
    final codec = SkirEditorCodec(
      TypeRegistry(bootstrapTypeCatalog(snapshot.catalog.definitions)),
    );
    final mutations = commit.mutations.isEmpty
        ? [
            for (final path in commit.changedPaths)
              EditorSetValue(path, path.read(root).valueOrNull!),
          ]
        : commit.mutations;
    final encoded = <skir.ElementValueMutation>[];
    for (final mutation in mutations) {
      final value = _encodeMutation(mutation, codec);
      if (value == null) {
        state = previous;
        return TypedMutationResult.invalid([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "An editor mutation could not be encoded",
            path: mutation.path,
          ),
        ]);
      }
      encoded.add(value);
    }
    try {
      final request = skir.UpdateElementValuesRequest(
        batchId: _nextBatchId("commit_value"),
        updates: [
          skir.ElementValueUpdate(
            id: recordId("element:$elementId"),
            expectedRevision: _revision(current),
            name: _elementName(current),
            mutations: encoded,
          ),
        ],
      );
      await _submitBatch(
        "element.value.update.v2",
        skir.UpdateElementValuesRequest.serializer.toBytes(request),
        skir.UpdateElementValuesResponse.serializer,
      );
      _incrementRevisions({elementId});
      return TypedMutationResult.success(
        revision: _revision(current) + 1,
        value: root,
      );
    } on ApiException catch (failure) {
      state = previous;
      if (failure.code == 409) {
        final remote = await _fetchElements();
        state = AsyncData(remote);
        final actual = remote.singleWhere((element) => element.id == elementId);
        return TypedMutationResult.conflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: _revision(actual),
          actualValue: _elementValue(actual),
        );
      }
      return TypedMutationResult.unavailable([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: failure.message,
        ),
      ]);
    }
  }

  Future<void> _updateFieldValue(
    String elementId,
    DataPath path,
    DataValue value,
  ) async {
    state.ensureReady();
    final previous = state;
    final data = previous.requireValue;
    final newData = data.map((element) {
      if (element.id != elementId) return element;
      return element.updateFieldValue(path, value);
    }).toList();

    state = AsyncValue.data(newData);
    final catalogState = ref.read(realmEditorCatalogProvider).value;
    final snapshot = catalogState?.snapshot;
    if (snapshot == null) {
      state = previous;
      throw ApiException.internalServerError();
    }
    final codec = SkirEditorCodec(
      TypeRegistry(bootstrapTypeCatalog(snapshot.catalog.definitions)),
    );
    final encodedPath = codec.encodePath(path).valueOrNull;
    final encodedValue = codec.encodeValue(value).valueOrNull;
    if (encodedPath == null || encodedValue == null) {
      state = previous;
      throw ApiException.badRequest("The edited value could not be encoded");
    }
    try {
      final request = skir.UpdateElementValuesRequest(
        batchId: _nextBatchId("update_value"),
        updates: [
          skir.ElementValueUpdate(
            id: recordId("element:$elementId"),
            expectedRevision: _revisions(data)[elementId]!,
            name: _elementName(
              data.singleWhere((element) => element.id == elementId),
            ),
            mutations: [
              skir.ElementValueMutation.createSetValue(
                path: encodedPath,
                value: encodedValue,
              ),
            ],
          ),
        ],
      );
      await _submitBatch(
        "element.value.update.v2",
        skir.UpdateElementValuesRequest.serializer.toBytes(request),
        skir.UpdateElementValuesResponse.serializer,
      );
      _incrementRevisions({elementId});
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> _submitBatch<Response>(
    String suffix,
    Uint8List bytes,
    Serializer<Response> serializer,
  ) async {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();
    final response = await ref.requestSkir(
      RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      ).request(suffix),
      bytes,
      serializer,
    );
    if (response is skir.CreateElementsResponse_successWrapper ||
        response is skir.MoveElementsToPagesResponse_successWrapper ||
        response is skir.MoveGraphElementsResponse_successWrapper ||
        response is skir.ResizeGraphElementsResponse_successWrapper ||
        response is skir.UpdateCueTimingsResponse_successWrapper ||
        response is skir.UpdateElementValuesResponse_successWrapper ||
        response is skir.DeleteElementsResponse_successWrapper ||
        response is skir.DuplicateElementsResponse_successWrapper) {
      return;
    }
    if (response is skir.CreateElementsResponse_conflictWrapper ||
        response is skir.MoveElementsToPagesResponse_conflictWrapper ||
        response is skir.MoveGraphElementsResponse_conflictWrapper ||
        response is skir.ResizeGraphElementsResponse_conflictWrapper ||
        response is skir.UpdateCueTimingsResponse_conflictWrapper ||
        response is skir.UpdateElementValuesResponse_conflictWrapper ||
        response is skir.DeleteElementsResponse_conflictWrapper ||
        response is skir.DuplicateElementsResponse_conflictWrapper) {
      throw ApiException.conflict("The page changed while it was being edited");
    }
    throw ApiException.badRequest("The batch was rejected");
  }

  void _incrementRevisions(Set<String> ids) {
    state = AsyncData([
      for (final element in state.requireValue)
        if (ids.contains(element.id))
          element.withRevision(_revision(element) + 1)
        else
          element,
    ]);
    ref
        .read(pageEntryCacheProvider.notifier)
        .replacePage(_currentPageId, state.requireValue);
  }
}

TypedValue _initialElementValue(
  ElementDefinition definition,
  TypeRegistry registry,
  SkirEditorCodec codec,
) {
  final initial = NamedType(
    definition.rootType,
  ).createInitialValue(registry: registry);
  final value = initial.valueOrNull;
  if (value == null) {
    throw ApiException.badRequest(initial.diagnostics.join("; "));
  }
  final encoded = codec.encodeValue(value);
  return encoded.valueOrNull ??
      (throw ApiException.badRequest(encoded.diagnostics.join("; ")));
}

List<PageElement> _decodePageElements(
  skir.PageDocument document,
  RealmEditorCatalogSnapshot snapshot,
) {
  final codec = SkirEditorCodec(
    TypeRegistry(bootstrapTypeCatalog(snapshot.catalog.definitions)),
  );
  final localIds = document.elements.map((element) => element.id.id).toSet();
  final links = [
    for (final reference in document.references)
      ElementLink(
        linkId: "${reference.source.id}:${reference.slot}",
        otherId: reference.target.id,
        path: reference.slot,
      ),
  ];
  final local = <PageElement>[];
  for (final element in document.elements) {
    final catalogEntry = snapshot.elements[element.elementType];
    final definition = catalogEntry == null
        ? null
        : ElementDefinition(
            rootType: catalogEntry.definition.type,
            name: catalogEntry.definition.name,
            description: catalogEntry.definition.description,
            icon: catalogEntry.definition.icon,
            color: catalogEntry.definition.color,
          );
    final decoded = codec.decodeValue(element.value).valueOrNull;
    final data = decoded is RecordValue ? decoded : null;
    final outgoing = [
      for (var index = 0; index < document.references.length; index++)
        if (document.references.elementAt(index).source.id == element.id.id)
          links[index],
    ];
    final incoming = [
      for (var index = 0; index < document.references.length; index++)
        if (document.references.elementAt(index).target.id == element.id.id)
          ElementLink(
            linkId: links[index].linkId,
            otherId: document.references.elementAt(index).source.id,
            path: links[index].path,
          ),
    ];
    final placement = element.placement;
    if (placement case skir.ElementPlacement_timelineSegmentV1Wrapper(
      value: final timing,
    )) {
      if (definition != null && data != null) {
        local.add(
          PageElement.cue(
            cue: Cue.segment(
              id: element.id.id,
              revision: element.revision,
              startFrame: timing.startFrame,
              endFrame: timing.endFrame,
              elementDefinition: definition,
              data: data,
              inwardLinks: incoming,
              outwardLinks: outgoing,
            ),
          ),
        );
      }
      continue;
    }
    if (placement case skir.ElementPlacement_timelineKeyframeV1Wrapper(
      value: final timing,
    )) {
      if (definition != null && data != null) {
        local.add(
          PageElement.cue(
            cue: Cue.keyframe(
              id: element.id.id,
              revision: element.revision,
              frame: timing.frame,
              elementDefinition: definition,
              data: data,
              inwardLinks: incoming,
            ),
          ),
        );
      }
      continue;
    }
    final entryPlacement = switch (placement) {
      skir.ElementPlacement_graphV1Wrapper(:final value) => EntryPlacement(
        x: value.x,
        y: value.y,
        width: value.width,
        height: value.height,
      ),
      skir.ElementPlacement_timelineEntryV1Wrapper(:final value) =>
        EntryPlacement(
          kind: EntryPlacementKind.timelineEntry,
          x: value.trackIndex,
          y: 0,
          width: 1,
          height: 1,
        ),
      _ => const EntryPlacement(x: 0, y: 0, width: 1, height: 1),
    };
    final entry = definition != null && data != null
        ? PageEntry.definition(
            definition: EntryDefinition(
              id: element.id.id,
              revision: element.revision,
              name: element.name,
              elementDefinition: definition,
              placement: entryPlacement,
              data: data,
              inwardEdges: incoming,
              outwardEdges: outgoing,
            ),
          )
        : PageEntry.missingElementDefinition(
            id: element.id.id,
            name: element.name,
            placement: entryPlacement,
            inwardLinks: incoming,
            outwardLinks: outgoing,
          );
    local.add(PageElement.entry(entry: entry));
  }

  final related = <PageElement>[];
  for (final summary in document.crossPageTargets) {
    if (localIds.contains(summary.id.id)) continue;
    if (!summary.exists || summary.elementType == null) {
      related.add(
        PageElement.entry(entry: PageEntry.nonexistent(id: summary.id.id)),
      );
      continue;
    }
    final catalogEntry = snapshot.elements[summary.elementType];
    final page = summary.page;
    if (catalogEntry == null || page == null) continue;
    related.add(
      PageElement.entry(
        entry: PageEntry.reference(
          id: summary.id.id,
          name: summary.name ?? summary.id.id,
          elementDefinition: ElementDefinition(
            rootType: catalogEntry.definition.type,
            name: catalogEntry.definition.name,
            description: catalogEntry.definition.description,
            icon: catalogEntry.definition.icon,
            color: catalogEntry.definition.color,
          ),
          pageId: page.id,
        ),
      ),
    );
  }
  return [...local, ...related];
}

Map<String, int> _revisions(List<PageElement> elements) => {
  for (final element in elements) element.id: _revision(element),
};

int _revision(PageElement element) => switch (element) {
  PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
    definition.revision,
  PageElementCue(:final cue) => cue.revision,
  _ => 0,
};

String _elementName(PageElement element) => switch (element) {
  PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
    definition.name,
  PageElementCue(:final cue) => cue.elementDefinition.name,
  _ => element.id,
};

RecordValue _elementValue(PageElement element) => switch (element) {
  PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
    definition.data,
  PageElementCue(cue: Segment(:final data) || Keyframe(:final data)) => data,
  _ => throw StateError("The element has no editable value"),
};

skir.ElementValueMutation? _encodeMutation(
  EditorStructuralMutation mutation,
  SkirEditorCodec codec,
) {
  final path = codec.encodePath(mutation.path).valueOrNull;
  if (path == null) return null;
  TypedValue? encode(DataValue value) => codec.encodeValue(value).valueOrNull;
  return switch (mutation) {
    EditorSetValue(:final value) => _encodeSetValue(path, value, codec),
    EditorInsertListItems(:final index, :final values) =>
      values.map(encode).nonNulls.length == values.length
          ? skir.ElementValueMutation.createInsertListItems(
              path: path,
              index: index,
              values: values.map(encode).nonNulls,
            )
          : null,
    EditorRemoveListItems(:final index, :final count) =>
      skir.ElementValueMutation.createRemoveListItems(
        path: path,
        index: index,
        count: count,
      ),
    EditorReorderListItems(
      :final sourceIndex,
      :final count,
      :final destinationIndex,
    ) =>
      skir.ElementValueMutation.createReorderListItems(
        path: path,
        sourceIndex: sourceIndex,
        count: count,
        destinationIndex: destinationIndex,
      ),
    EditorDuplicateListItems(
      :final sourceIndex,
      :final count,
      :final destinationIndex,
    ) =>
      skir.ElementValueMutation.createDuplicateListItems(
        path: path,
        sourceIndex: sourceIndex,
        count: count,
        destinationIndex: destinationIndex,
      ),
    EditorPutMapEntries(:final entries) =>
      entries.every(
            (entry) => encode(entry.key) != null && encode(entry.value) != null,
          )
          ? skir.ElementValueMutation.createPutMapEntries(
              path: path,
              entries: [
                for (final entry in entries)
                  skir.PutMapEntry(
                    key: encode(entry.key)!,
                    value: encode(entry.value)!,
                  ),
              ],
            )
          : null,
    EditorRemoveMapEntries(:final keys) =>
      keys.map(encode).nonNulls.length == keys.length
          ? skir.ElementValueMutation.createRemoveMapEntries(
              path: path,
              keys: keys.map(encode).nonNulls,
            )
          : null,
    EditorReplaceConcreteType(:final concreteType, :final value) =>
      _encodeConcreteReplacement(path, concreteType, value, codec),
  };
}

skir.ElementValueMutation? _encodeSetValue(
  wire_path.DataPath path,
  DataValue value,
  SkirEditorCodec codec,
) {
  final encoded = codec.encodeValue(value).valueOrNull;
  return encoded == null
      ? null
      : skir.ElementValueMutation.createSetValue(path: path, value: encoded);
}

skir.ElementValueMutation? _encodeConcreteReplacement(
  wire_path.DataPath path,
  ResolvedTypeRef concreteType,
  DataValue value,
  SkirEditorCodec codec,
) {
  final type = codec.encodeType(concreteType).valueOrNull;
  final encoded = codec.encodeValue(value).valueOrNull;
  if (type == null || encoded == null) return null;
  return skir.ElementValueMutation.createReplaceConcreteType(
    path: path,
    concreteType: type,
    value: encoded,
  );
}

extension on PageElement {
  PageElement withRevision(int revision) => switch (this) {
    PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
      PageElement.entry(
        entry: PageEntry.definition(
          definition: definition.copyWith(revision: revision),
        ),
      ),
    PageElementCue(:final cue) => PageElement.cue(
      cue: switch (cue) {
        Segment() => cue.copyWith(revision: revision),
        Keyframe() => cue.copyWith(revision: revision),
        _ => cue,
      },
    ),
    _ => this,
  };
}

skir.ElementPlacement _updatedCuePlacement(
  PageElement element,
  int startFrame,
  int endFrame,
) => switch (element) {
  PageElementCue(cue: Segment()) =>
    skir.ElementPlacement.createTimelineSegmentV1(
      startFrame: startFrame,
      endFrame: endFrame,
    ),
  PageElementCue(cue: Keyframe()) =>
    skir.ElementPlacement.createTimelineKeyframeV1(frame: startFrame),
  _ => throw ApiException.badRequest("The element is not a cue"),
};

skir.ElementPlacement _entryPlacementToSkir(EntryPlacement placement) =>
    switch (placement.kind) {
      EntryPlacementKind.graph => skir.ElementPlacement.createGraphV1(
        x: placement.x,
        y: placement.y,
        width: placement.width,
        height: placement.height,
      ),
      EntryPlacementKind.timelineEntry =>
        skir.ElementPlacement.createTimelineEntryV1(trackIndex: placement.x),
    };

var _batchSequence = 0;

String _nextBatchId(String operation) =>
    "$operation:${DateTime.now().microsecondsSinceEpoch}:${_batchSequence++}";

@Freezed(unionKey: "_kind")
abstract class PageElement with _$PageElement {
  const factory PageElement.entry({required PageEntry entry}) =
      PageElementEntry;

  const factory PageElement.cue({required Cue cue}) = PageElementCue;
}

extension PageElementExtension on PageElement {
  String get id => switch (this) {
    PageElementEntry(:final entry) => entry.id,
    PageElementCue(:final cue) => cue.id,
    _ => throw StateError("Unknown page element type"),
  };

  PageElement moveTo(int x, int y) {
    return switch (this) {
      PageElementEntry(:final entry) => PageElement.entry(
        entry: switch (entry) {
          DefinitionPageEntry() => entry.copyWith.definition.placement(
            x: x,
            y: y,
          ),
          MissingElementDefinitionPageEntry() => entry.copyWith.placement(
            x: x,
            y: y,
          ),
          _ => entry,
        },
      ),
      _ => this,
    };
  }

  PageElement resizeTo(int width, int height) {
    return switch (this) {
      PageElementEntry(:final entry) => PageElement.entry(
        entry: switch (entry) {
          DefinitionPageEntry() => entry.copyWith.definition.placement(
            width: width,
            height: height,
          ),
          MissingElementDefinitionPageEntry() => entry.copyWith.placement(
            width: width,
            height: height,
          ),
          _ => entry,
        },
      ),
      _ => this,
    };
  }

  PageElement updateCueTo(int startFrame, int endFrame) {
    return switch (this) {
      PageElementCue(:final cue) => PageElement.cue(
        cue: switch (cue) {
          Segment() => cue.copyWith(startFrame: startFrame, endFrame: endFrame),
          Keyframe() => cue.copyWith(frame: startFrame),
          _ => cue,
        },
      ),
      _ => this,
    };
  }

  PageElement updateFieldValue(DataPath path, DataValue value) {
    return switch (this) {
      PageElementEntry(:final entry) => PageElement.entry(
        entry: switch (entry) {
          DefinitionPageEntry() => entry.copyWith.definition(
            data: entry.definition.data.updatedAt(path, value),
          ),
          _ => entry,
        },
      ),
      PageElementCue(:final cue) => PageElement.cue(
        cue: switch (cue) {
          Segment() => cue.copyWith(data: cue.data.updatedAt(path, value)),
          Keyframe() => cue.copyWith(data: cue.data.updatedAt(path, value)),
          _ => cue,
        },
      ),
      _ => this,
    };
  }
}

extension on RecordValue {
  RecordValue updatedAt(DataPath path, DataValue value) {
    final updated = path.replace(this, value).valueOrNull;
    return updated is RecordValue ? updated : this;
  }
}

@freezed
abstract class ElementLink with _$ElementLink {
  @Assert("linkId != \"\"", "Link ID must not be empty.")
  @Assert("otherId != \"\"", "Other ID must not be empty.")
  const factory ElementLink({
    required String linkId,
    required String otherId,
    required String path,
  }) = _ElementLink;

  factory ElementLink.fromJson(Map<String, dynamic> json) =>
      _$ElementLinkFromJson(json);
}
