part of "authoring_session.dart";

/// Maintains the session's ordered live projection and lifecycle recovery.
///
/// Authoring events are applied only when their sequence immediately follows
/// the canonical sequence. Events received during refresh or ahead of a gap
/// stay buffered until a snapshot makes the sequence continuous. Compiled
/// content events refresh only retained page scopes because compilation can
/// change page related state without changing the authoring event stream.
mixin _AuthoringSessionSync on _$AuthoringSession, _AuthoringSessionSnapshots {
  final Map<_AuthoringScope, int> _scopeCounts = {};
  final Map<_AuthoringScope, Future<void>> _scopeReadiness = {};
  final List<skir.AuthoringChanged> _buffer = [];

  NatsSubscription? _subscription;
  StreamSubscription<NatsMessage>? _messages;
  NatsSubscription? _compiledSubscription;
  StreamSubscription<NatsMessage>? _compiledMessages;
  StreamSubscription<NatsConnectionState>? _lifecycle;
  Future<void>? _refreshOperation;
  var _refreshRequested = false;
  late Future<void> _startOperation;
  var _needsReconnectRefresh = false;
  var _disposed = false;

  late NatsClient _client;
  @override
  late RealmServiceAddress _address;

  Future<void> _start() async {
    try {
      _lifecycle = _client.connectionStateChanges.listen(_onLifecycle);
      _onLifecycle(_client.connectionState);

      _subscription = await _client.subscribe(
        _address.event("library.authoring.changed"),
      );
      _compiledSubscription = await _client.subscribe(
        _address.event("compiled.content.watch"),
      );
      if (_disposed) {
        await _subscription?.unsubscribe();
        await _compiledSubscription?.unsubscribe();
        return;
      }

      _messages = _subscription?.messages.listen(
        _onMessage,
        onError: (Object _, StackTrace _) => _scheduleRefresh(),
      );
      _compiledMessages = _compiledSubscription?.messages.listen(
        _onCompiledMessage,
        onError: (Object _, StackTrace _) => _scheduleRefresh(),
      );
    } on Object catch (error, stackTrace) {
      if (!_disposed) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _onMessage(NatsMessage message) {
    final change = skir.AuthoringChanged.serializer.fromBytes(message.payload);
    _accept(change);
  }

  void _onCompiledMessage(NatsMessage message) {
    final event = skir.WatchCompiledContentResponse.serializer.fromBytes(
      message.payload,
    );
    switch (event) {
      case skir.WatchCompiledContentResponse_activatedWrapper() ||
          skir.WatchCompiledContentResponse_blockedWrapper():
        _schedulePageRefresh();
      case skir.WatchCompiledContentResponse_initialWrapper() ||
          skir.WatchCompiledContentResponse_internalErrorWrapper() ||
          skir.WatchCompiledContentResponse_unknown():
    }
  }

  /// Marks the canonical model stale across a reconnect boundary.
  void _onLifecycle(NatsConnectionState connection) {
    switch (connection) {
      case NatsReconnecting() || NatsFailed():
        _needsReconnectRefresh = true;
      case NatsConnected() when _needsReconnectRefresh:
        _needsReconnectRefresh = false;
        _scheduleRefresh();
      case NatsConnecting() || NatsConnected() || NatsClosed():
    }
  }

  /// Accepts an event only when it preserves sequence continuity.
  ///
  /// Duplicate and older events are harmless. A future event is buffered and
  /// causes a snapshot refresh rather than being applied out of order.
  void _accept(skir.AuthoringChanged change) {
    if (_refreshOperation != null || state.sequence == null) {
      _buffer.add(change);
      return;
    }
    final current = state.sequence!;
    if (change.sequence <= current) return;
    if (change.sequence != current + 1) {
      _buffer.add(change);
      _scheduleRefresh();
      return;
    }
    _applyEvent(change);
  }

  void _scheduleRefresh() {
    unawaited(_refresh().catchError((Object _) {}));
  }

  Future<void> _refresh() {
    _refreshRequested = true;
    final active = _refreshOperation;
    if (active != null) return active;
    return _refreshOperation = _runRefresh().whenComplete(
      () => _refreshOperation = null,
    );
  }

  void _schedulePageRefresh() {
    if (!_scopeCounts.keys.any((scope) => scope is _PageScope)) return;
    _scheduleRefresh();
  }

  /// Reconciles all held scopes through serialized authoritative snapshots.
  ///
  /// Refresh requests coalesce, and a request raised during a fetch causes one
  /// more pass. A snapshot older than the current sequence cannot replace the
  /// read model.
  Future<void> _runRefresh() async {
    if (_disposed || _scopeCounts.isEmpty) return;
    state = state.copyWith(refreshing: true);
    try {
      while (_refreshRequested && !_disposed && _scopeCounts.isNotEmpty) {
        _refreshRequested = false;
        final scopes = _scopeCounts.keys.toList();
        final snapshot = await _fetchSnapshot(scopes);
        if (_disposed) return;
        if (snapshot.sequence >= (state.sequence ?? 0)) {
          _applySnapshot(snapshot);
          _drainBuffer();
        }
      }
    } finally {
      if (!_disposed) state = state.copyWith(refreshing: false);
    }
  }

  /// Applies buffered events after a snapshot restored sequence continuity.
  void _drainBuffer() {
    if (state.sequence == null) return;

    _buffer.sort((left, right) => left.sequence.compareTo(right.sequence));
    final buffered = List<skir.AuthoringChanged>.of(_buffer);
    _buffer.clear();

    for (var index = 0; index < buffered.length; index++) {
      final change = buffered[index];
      if (change.sequence <= state.sequence!) continue;
      if (change.sequence != state.sequence! + 1) {
        _buffer.addAll(buffered.skip(index));
        _scheduleRefresh();
        return;
      }
      _applyEvent(change);
    }
  }

  /// Applies a contiguous event and refreshes retained pages it affects
  /// indirectly.
  void _applyEvent(skir.AuthoringChanged event) {
    _applyChanges(event.changes, sequence: event.sequence);
    final pages = event.indirectlyAffectedResources
        .whereType<skir.AuthoringResourceRef_pageWrapper>()
        .map((resource) => resource.value)
        .where((pageId) => _scopeCounts.containsKey(_PageScope(pageId)))
        .toSet();

    if (pages.isNotEmpty) _scheduleRefresh();
  }

  void _applyChanges(
    Iterable<skir.AuthoringResourceChange> changes, {
    int? sequence,
  }) {
    final books = Map<skir.RecordId, skir.Book>.of(state.books);
    final tags = Map<skir.RecordId, skir.Tag>.of(state.tags);
    final pages = Map<skir.RecordId, skir.Page>.of(state.pages);
    final documents = Map<skir.RecordId, skir.PageDocument>.of(state.documents);

    for (final change in changes) {
      switch (change) {
        case skir.AuthoringResourceChange_upsertBookWrapper(:final value):
          books[value.id] = value;
        case skir.AuthoringResourceChange_removeBookWrapper(:final value):
          books.remove(value);
        case skir.AuthoringResourceChange_upsertTagWrapper(:final value):
          tags[value.id] = value;
        case skir.AuthoringResourceChange_removeTagWrapper(:final value):
          tags.remove(value);
        case skir.AuthoringResourceChange_upsertPageWrapper(:final value):
          pages[value.id] = value;
          final document = documents[value.id];
          if (document != null) {
            documents[value.id] = (document.toMutable()..page = value)
                .toFrozen();
          }
        case skir.AuthoringResourceChange_removePageWrapper(:final value):
          pages.remove(value);
          documents.remove(value);
        case skir.AuthoringResourceChange_upsertElementWrapper(:final value):
          documents.updateAll(
            (_, document) => _removeElement(document, value.id),
          );
          final document = documents[value.page];
          if (document != null) {
            documents[value.page] = _upsertElement(document, value);
          }
        case skir.AuthoringResourceChange_removeElementWrapper(:final value):
          documents.updateAll((_, document) => _removeElement(document, value));
        case skir.AuthoringResourceChange_unknown():
          throw ApiException.unknownResponseMessage();
      }
    }

    state = AuthoringSessionState(
      sequence: sequence ?? state.sequence,
      books: Map.unmodifiable(books),
      tags: Map.unmodifiable(tags),
      pages: Map.unmodifiable(pages),
      documents: Map.unmodifiable(documents),
      refreshing: state.refreshing,
    );
  }

  skir.PageDocument _upsertElement(
    skir.PageDocument document,
    skir.PageElement element,
  ) =>
      (document.toMutable()
            ..elements = [
              for (final current in document.elements)
                if (current.id != element.id) current,
              element,
            ])
          .toFrozen();

  skir.PageDocument _removeElement(
    skir.PageDocument document,
    skir.RecordId elementId,
  ) =>
      (document.toMutable()
            ..elements = document.elements.where(
              (element) => element.id != elementId,
            ))
          .toFrozen();

  Future<void> _dispose() async {
    _disposed = true;
    await _messages?.cancel();
    await _compiledMessages?.cancel();
    await _lifecycle?.cancel();
    await _subscription?.unsubscribe();
    await _compiledSubscription?.unsubscribe();
  }
}
