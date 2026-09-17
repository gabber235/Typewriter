part of "tag_authoring_consistency_test.dart";

const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.snapshot.get";
const _batchSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.batch.apply";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.library.authoring.changed";

final _organization = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _tagId = recordId("tag:tag1");
final _colorPath = DataPath.root.field("color");

Tag _documentTag(EditorDocument document) {
  final seed = Tag(
    tagId: _tagId,
    name: "unused",
    color: Colors.blue,
    parentIds: const [],
    placement: Placement(x: 0, y: 0, width: 4, height: 1),
  );
  final value = seed.withInspectorValue(document.confirmedValue);
  if (value == null) throw StateError("The editor document is not a Tag");
  return value;
}

final class _Harness {
  _Harness._(this.nats) {
    nats.registerHandler(_snapshotSubject, (_) => snapshot());
    container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_organization),
        realmIdProvider.overrideWithValue(_realm),
        realmEditorCatalogSourceProvider.overrideWithValue(
          const UnavailableRealmEditorCatalogSource(),
        ),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
  }

  factory _Harness.transportOnly() => _Harness._(FakeNatsClient());

  final FakeNatsClient nats;
  late final ProviderContainer container;
  AuthoringScopeLease? _libraryLease;
  LocalWorkSession? directWorkspace;
  int sequence = 1;
  Tag tag = _tag();
  final _subscriptions = <ProviderSubscription<dynamic>>[];

  static Future<_Harness> create() async {
    final harness = _Harness._(FakeNatsClient());
    final session = authoringSessionProvider(_organization, _realm);
    harness._subscriptions.add(
      harness.container.listen(session, (_, _) {}, fireImmediately: true),
    );
    await harness.container.pump();
    harness._libraryLease = harness.container
        .read(session.notifier)
        .acquireLibrary();
    await harness._libraryLease!.ready;
    expect(harness.nats.subscriptionSubjects, isNotEmpty);
    expect(
      harness.container.read(session).sequence,
      1,
      reason: "requests=${harness.nats.requests.map((value) => value.subject)}",
    );
    harness._subscriptions.add(
      harness.container.listen(
        canonicalTagsProvider,
        (_, _) {},
        fireImmediately: true,
      ),
    );
    harness._subscriptions.add(
      harness.container.listen(
        selectedProvider,
        (_, _) {},
        fireImmediately: true,
      ),
    );
    harness._subscriptions.add(
      harness.container.listen(
        inspectionSessionProvider,
        (_, _) {},
        fireImmediately: true,
      ),
    );
    harness.container.read(inspectionSessionProvider);
    await harness.container.read(canonicalTagsProvider.future);
    expect(
      harness.container.read(canonicalTagsProvider).requireValue,
      hasLength(1),
    );
    return harness;
  }

  Uint8List snapshot() => skir.GetAuthoringSnapshotResponse.serializer.toBytes(
    skir.GetAuthoringSnapshotResponse.createSuccess(
      sequence: sequence,
      slices: [
        skir.AuthoringSnapshotSlice.createLibrary(
          books: const [],
          tags: [tag.toWire()],
        ),
      ],
    ),
  );

  Uint8List appliedResponse(String batchId) =>
      skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createApplied(
          sequence: sequence,
          batchId: batchId,
          changes: [skir.AuthoringResourceChange.wrapUpsertTag(tag.toWire())],
          indirectlyAffectedResources: const [],
        ),
      );

  void emitEvent(String batchId) {
    nats.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(
        skir.AuthoringChanged(
          sequence: sequence,
          batchId: batchId,
          changes: [skir.AuthoringResourceChange.wrapUpsertTag(tag.toWire())],
          indirectlyAffectedResources: const [],
        ),
      ),
    );
  }

  Future<TransactionalEditorSource> openEditor() async {
    container.read(selectionProvider.notifier).select(TagIdentifier(_tagId));
    await waitForProvider(
      container,
      selectedProvider,
      (value) => value.hasValue && value.requireValue.isNotEmpty,
      description: "selected tag",
    );
    await container.pump();
    container.read(inspectedSelectionProvider);
    await container.pump();

    final workspace = container.read(localWorkControllerProvider);
    final key = EditorResourceKey(
      scope: EditorResourceScope(
        organizationId: _organization,
        realmId: _realm,
      ),
      identity: _tagId,
    );
    final source = workspace.source(key);
    if (source is! TransactionalEditorSource) {
      throw StateError("The selected tag did not install an editor source");
    }
    return source;
  }

  TransactionalEditorSource openDirectEditor() {
    final repository = container
        .read(resourceRepositoriesProvider)
        .authoring(_organization, _realm);
    final workspace = LocalWorkSession();
    directWorkspace = workspace;
    final resource = TagEditorResource(repository, _tagId);
    final source = workspace.editor(
      ResourceEditorTarget(
        targetId: _tagId,
        label: tag.name,
        resource: resource,
        snapshot: TagEditorSnapshot(tag, sequence),
      ),
    ) as TransactionalEditorSource;
    workspace.retain(resource.key);
    return source;
  }

  Future<void> dispose() async {
    _libraryLease?.release();
    directWorkspace?.dispose();
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    container.dispose();
    await nats.dispose();
  }
}

Tag _tag({String name = "initial", Color color = Colors.blue}) => Tag(
  tagId: _tagId,
  name: name,
  color: color,
  parentIds: const [],
  placement: const Placement(x: 0, y: 0, width: 4, height: 1),
);
