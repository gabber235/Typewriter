part of "authoring_session.dart";

mixin _AuthoringSessionSync on _$AuthoringSession, _AuthoringSessionSnapshots {
  final Map<_AuthoringScope, int> _scopeCounts = {};
  final Map<_AuthoringScope, Future<void>> _scopeReadiness = {};
  final List<wire.AuthoringChanged> _buffer = [];

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
    final change = wire.AuthoringChanged.serializer.fromBytes(message.payload);
    _accept(change);
  }

  void _onCompiledMessage(NatsMessage message) {
    final event = compiled_wire.WatchCompiledContentResponse.serializer
        .fromBytes(message.payload);
    switch (event) {
      case compiled_wire.WatchCompiledContentResponse_activatedWrapper() ||
          compiled_wire.WatchCompiledContentResponse_blockedWrapper():
        _schedulePageRefresh();
      case compiled_wire.WatchCompiledContentResponse_initialWrapper() ||
          compiled_wire.WatchCompiledContentResponse_internalErrorWrapper() ||
          compiled_wire.WatchCompiledContentResponse_unknown():
    }
  }

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

  void _accept(wire.AuthoringChanged change) {
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

  void _drainBuffer() {
    if (state.sequence == null) return;
    _buffer.sort((left, right) => left.sequence.compareTo(right.sequence));
    final buffered = List<wire.AuthoringChanged>.of(_buffer);
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

  void _applyEvent(wire.AuthoringChanged event) {
    _applyChanges(event.changes, sequence: event.sequence);
    final pages = event.indirectlyAffectedResources
        .whereType<wire.AuthoringResourceRef_pageWrapper>()
        .map((resource) => resource.value)
        .where((pageId) => _scopeCounts.containsKey(_PageScope(pageId)))
        .toSet();
    if (pages.isNotEmpty) _scheduleRefresh();
  }

  void _applyChanges(
    Iterable<wire.AuthoringResourceChange> changes, {
    int? sequence,
  }) {
    final books = Map<skir.RecordId, wire.Book>.of(state.books);
    final tags = Map<skir.RecordId, wire.Tag>.of(state.tags);
    final pages = Map<skir.RecordId, wire.Page>.of(state.pages);
    final documents = Map<skir.RecordId, wire.PageDocument>.of(state.documents);
    for (final change in changes) {
      switch (change) {
        case wire.AuthoringResourceChange_upsertBookWrapper(:final value):
          books[value.id] = value;
        case wire.AuthoringResourceChange_removeBookWrapper(:final value):
          books.remove(value);
        case wire.AuthoringResourceChange_upsertTagWrapper(:final value):
          tags[value.id] = value;
        case wire.AuthoringResourceChange_removeTagWrapper(:final value):
          tags.remove(value);
        case wire.AuthoringResourceChange_upsertPageWrapper(:final value):
          pages[value.id] = value;
          final document = documents[value.id];
          if (document != null) {
            documents[value.id] = (document.toMutable()..page = value)
                .toFrozen();
          }
        case wire.AuthoringResourceChange_removePageWrapper(:final value):
          pages.remove(value);
          documents.remove(value);
        case wire.AuthoringResourceChange_upsertElementWrapper(:final value):
          documents.updateAll(
            (_, document) => _removeElement(document, value.id),
          );
          final document = documents[value.page];
          if (document != null) {
            documents[value.page] = _upsertElement(document, value);
          }
        case wire.AuthoringResourceChange_removeElementWrapper(:final value):
          documents.updateAll((_, document) => _removeElement(document, value));
        case wire.AuthoringResourceChange_unknown():
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

  wire.PageDocument _upsertElement(
    wire.PageDocument document,
    wire.PageElement element,
  ) =>
      (document.toMutable()
            ..elements = [
              for (final current in document.elements)
                if (current.id != element.id) current,
              element,
            ])
          .toFrozen();

  wire.PageDocument _removeElement(
    wire.PageDocument document,
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
