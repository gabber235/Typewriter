part of "authoring_session.dart";

final class AuthoringResourceRepository {
  AuthoringResourceRepository(this.session, this.organization, this.realm) {
    _changeTransfers = AuthoringChangedTransferAssembler(
      onExpired: (_) => _invalidations.add(null),
    );
  }

  final ResourceRepositories session;
  final skir.RecordId organization;
  final skir.RecordId realm;
  final _changes = StreamController<skir.AuthoringChanged>.broadcast(
    sync: true,
  );
  final _invalidations = StreamController<void>.broadcast(sync: true);
  late final AuthoringChangedTransferAssembler _changeTransfers;
  final Completer<void> _disposed = Completer<void>();

  Stream<skir.AuthoringChanged> get changes => _changes.stream;
  Stream<void> get invalidations => _invalidations.stream;

  NatsSubscription? _authoringSubscription;
  StreamSubscription<NatsMessage>? _authoringMessages;
  StreamSubscription<NatsConnectionState>? _lifecycle;
  var _started = false;
  var _isDisposed = false;
  var _reconnectNeedsRefresh = false;

  RealmServiceAddress get address =>
      RealmServiceAddress(organizationId: organization, realmId: realm);

  bool isScopedTo(skir.RecordId organizationId, skir.RecordId realmId) =>
      organization == organizationId && realm == realmId;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final client = session.transport.client;
    _lifecycle = client.connectionStateChanges.listen(_onLifecycle);
    _onLifecycle(client.connectionState);
    final subscription = await client.subscribe(
      address.event("editor.authoring.changed"),
    );
    if (_isDisposed) {
      await subscription.unsubscribe();
      return;
    }
    _authoringSubscription = subscription;
    _authoringMessages = subscription.messages.listen(
      _acceptAuthoringMessage,
      onError: (Object _, StackTrace _) => _invalidations.add(null),
    );
  }

  Future<skir.AuthoringSnapshot> fetch({
    required skir.CatalogGeneration generation,
    skir.SnapshotId? snapshot,
  }) async {
    session.checkActive();
    final transferId = uuid.v4();
    final request = skir.QueryAuthoringSnapshotRequest(
      generation: generation,
      snapshot: snapshot,
      transferId: transferId,
    );
    final responses = session.transport.watchRequest(
      address.request("editor.authoring.snapshot.query"),
      boundedTransferUpdateSubject(
        address.event("editor.authoring.snapshot.query"),
        transferId,
      ),
      skir.QueryAuthoringSnapshotRequest.serializer.toBytes(request),
      skir.QueryAuthoringSnapshotResponse.serializer,
    );
    final assembler = AuthoringSnapshotTransferAssembler();
    final result = await assembler.assemble(
      responses.map(
        (response) => switch (response) {
          skir.QueryAuthoringSnapshotResponse_chunkWrapper(:final value) =>
            value,
          skir.QueryAuthoringSnapshotResponse_catalogChangedWrapper(
            :final value,
          ) =>
            throw CatalogGenerationChanged(value.actualGeneration),
          skir.QueryAuthoringSnapshotResponse_unavailableWrapper(
            :final value,
          ) =>
            throw AuthoringSnapshotTransferUnavailable(value),
          _ => throw ApiException.internalServerError(),
        },
      ),
      cancelled: _disposed.future,
    );
    session.checkActive();
    return result;
  }

  Future<skir.SearchAuthoringResponse> search(
    skir.SearchAuthoringRequest request,
  ) async {
    session.checkActive();
    final response = await session.transport.request(
      address.request("editor.authoring.search"),
      skir.SearchAuthoringRequest.serializer.toBytes(request),
      skir.SearchAuthoringResponse.serializer,
    );
    session.checkActive();
    return response;
  }

  Future<skir.TypePreviewResult> previewTypeArgumentChange(
    skir.PreviewTypeArgumentChangeRequest request,
  ) async {
    session.checkActive();
    final response = await session.transport.request(
      address.request("editor.authoring.type.preview"),
      skir.PreviewTypeArgumentChangeRequest.serializer.toBytes(request),
      skir.PreviewTypeArgumentChangeResponse.serializer,
    );
    session.checkActive();
    return switch (response) {
      skir.PreviewTypeArgumentChangeResponse_resultWrapper(:final value) =>
        value,
      _ => throw ApiException.internalServerError(),
    };
  }

  PreparedCommit<skir.CommitPreparedEditResponse> prepareCommit(
    skir.PreparedEdit edit,
  ) => session.transport.prepare(
    address.request("editor.authoring.edit.commit"),
    skir.PreparedEdit.serializer.toBytes(edit),
    skir.CommitPreparedEditResponse.serializer,
    submissionId: edit.id.value,
    replay: SubmissionReplay.identicalRequest,
    label: "Save Realm changes",
    resources: {
      for (final resource in _editedResources(edit))
        (organization, realm, resource),
    },
    classify: (response) => switch (response) {
      skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult_committedWrapper(),
      ) =>
        MutationResponseDisposition.confirmed,
      skir.CommitPreparedEditResponse_internalErrorWrapper() ||
      skir.CommitPreparedEditResponse_unknown() =>
        MutationResponseDisposition.uncertain,
      _ => MutationResponseDisposition.rejected,
    },
    rejectionMessage: (response) => response.rejectionMessage,
  );

  PreparedCommit<skir.CommitTypeArgumentChangeResponse> prepareTypeCommit(
    skir.TypeArgumentChangePreview preview,
  ) => session.transport.prepare(
    address.request("editor.authoring.type.commit"),
    skir.TypeArgumentChangePreview.serializer.toBytes(preview),
    skir.CommitTypeArgumentChangeResponse.serializer,
    submissionId:
        "type:${preview.sourceSnapshot.value}:${preview.resource.value}:${preview.next}",
    replay: SubmissionReplay.identicalRequest,
    label: "Apply type argument repair",
    resources: {(organization, realm, preview.resource)},
    classify: (response) => switch (response) {
      skir.CommitTypeArgumentChangeResponse_resultWrapper(
        value: skir.CommitResult_committedWrapper(),
      ) =>
        MutationResponseDisposition.confirmed,
      skir.CommitTypeArgumentChangeResponse_internalErrorWrapper() ||
      skir.CommitTypeArgumentChangeResponse_unknown() =>
        MutationResponseDisposition.uncertain,
      _ => MutationResponseDisposition.rejected,
    },
    rejectionMessage: (response) => response.rejectionMessage,
  );

  void _acceptAuthoringMessage(NatsMessage message) {
    if (_isDisposed) return;
    try {
      final result = skir.AuthoringChangedTransferResult.serializer.fromBytes(
        message.payload,
      );
      final changed = _changeTransfers.accept(result);
      if (changed != null) _changes.add(changed);
    } on Object {
      _invalidations.add(null);
    }
  }

  void _onLifecycle(NatsConnectionState lifecycle) {
    if (_isDisposed) return;
    switch (lifecycle) {
      case NatsReconnecting() || NatsFailed():
        _reconnectNeedsRefresh = true;
      case NatsConnected() when _reconnectNeedsRefresh:
        _reconnectNeedsRefresh = false;
        _invalidations.add(null);
      case NatsConnecting() || NatsConnected() || NatsClosed():
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _disposed.complete();
    _changeTransfers.clear();
    unawaited(_authoringMessages?.cancel());
    unawaited(_lifecycle?.cancel());
    unawaited(_authoringSubscription?.unsubscribe());
    unawaited(_changes.close());
    unawaited(_invalidations.close());
  }
}

extension CommitPreparedEditResponseMessaging
    on skir.CommitPreparedEditResponse {
  String get rejectionMessage => switch (this) {
    skir.CommitPreparedEditResponse_resultWrapper(:final value) =>
      value.rejectionMessage,
    _ => "The operation was rejected",
  };
}

extension CommitTypeArgumentChangeResponseMessaging
    on skir.CommitTypeArgumentChangeResponse {
  String get rejectionMessage => switch (this) {
    skir.CommitTypeArgumentChangeResponse_resultWrapper(:final value) =>
      value.rejectionMessage,
    _ => "The operation was rejected",
  };
}

extension CommitResultMessaging on skir.CommitResult {
  String get rejectionMessage => switch (this) {
    skir.CommitResult_rejectedWrapper(:final value) => value.rejectionMessage,
    skir.CommitResult_conflictWrapper() =>
      "The Realm changed before this edit was saved",
    skir.CommitResult_catalogChangedWrapper() => "The editor catalog changed",
    _ => "The operation was rejected",
  };
}

extension ValueProblemMessages on Iterable<skir.ValueProblem> {
  String get rejectionMessage {
    final values = toList(growable: false);
    if (values.isEmpty) return "The Realm rejected this edit";
    const shownLimit = 5;
    final shown = values
        .take(shownLimit)
        .map((problem) => problem.locatedMessage)
        .join("; ");
    final remaining = values.length - shownLimit;
    return remaining > 0
        ? "The Realm rejected this edit: $shown; and $remaining more"
        : "The Realm rejected this edit: $shown";
  }
}

extension ValueProblemMessaging on skir.ValueProblem {
  String get locatedMessage {
    final path = location.path.segments
        .map(
          (segment) => switch (segment) {
            skir.PathSegment_fieldWrapper(:final value) => value.name,
            skir.PathSegment_itemWrapper(:final value) => value.id.value,
            skir.PathSegment.mapKey => "key",
            skir.PathSegment.mapValue => "value",
            _ => "unknown",
          },
        )
        .join(".");
    final locationLabel = path.isEmpty
        ? location.resource.value
        : "${location.resource.value}:$path";
    return "$code at $locationLabel";
  }
}

Iterable<skir.ResourceId> _editedResources(skir.PreparedEdit edit) sync* {
  for (final intent in edit.intents) {
    switch (intent) {
      case skir.EditIntent_createResourceWrapper(:final value):
        yield value.id;
      case skir.EditIntent_deleteResourceWrapper(:final value):
        yield value.id;
      case skir.EditIntent_setValueWrapper(:final value):
        yield value.at.resource;
      case skir.EditIntent_insertWrapper(:final value):
        yield value.at.resource;
      case skir.EditIntent_removeWrapper(:final value):
        yield value.at.resource;
      case skir.EditIntent_moveWrapper(:final value):
        yield value.at.resource;
      case skir.EditIntent_connectRelationWrapper(:final value):
        yield value.source.source;
        yield value.target;
      case skir.EditIntent_disconnectRelationWrapper(:final value):
        yield value.location.resource;
      case skir.EditIntent_retagWrapper(:final value):
        yield value.at.resource;
      case skir.EditIntent_configureResourceWrapper(:final value):
        yield value.resource;
      case skir.EditIntent_unknown():
    }
  }
}
