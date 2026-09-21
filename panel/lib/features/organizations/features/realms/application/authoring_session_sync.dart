part of "authoring_session.dart";

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
        (_) => _scheduleRefresh(),
        onError: (Object _, StackTrace _) => _scheduleRefresh(),
      );
    } on Object catch (error, stackTrace) {
      if (!_disposed) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _onMessage(NatsMessage message) {
    _accept(skir.AuthoringChanged.serializer.fromBytes(message.payload));
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

  void _applyEvent(skir.AuthoringChanged event) {
    if (state.generation != null && event.generation != state.generation) {
      _scheduleRefresh();
      return;
    }
    final resources = Map<skir.ResourceId, skir.AuthoringResource>.of(
      state.resources,
    );
    final edges = Map<skir.AuthoringEdgeId, skir.AuthoringEdge>.of(state.edges);
    final presentations = Map<skir.ResourceId, skir.PresentationSubject>.of(
      state.presentations,
    );
    for (final change in event.resources) {
      switch (change) {
        case skir.AuthoringResourceChange_upsertWrapper(:final value):
          resources[value.id] = value;
          presentations.remove(value.id);
        case skir.AuthoringResourceChange_removeWrapper(:final value):
          resources.remove(value);
          presentations.remove(value);
        case skir.AuthoringResourceChange_unknown():
          throw ApiException.unknownResponseMessage();
      }
    }
    for (final change in event.edges) {
      switch (change) {
        case skir.AuthoringEdgeChange_upsertWrapper(:final value):
          edges[value.id] = value;
        case skir.AuthoringEdgeChange_removeWrapper(:final value):
          edges.remove(value);
        case skir.AuthoringEdgeChange_unknown():
          throw ApiException.unknownResponseMessage();
      }
    }
    state = state.copyWith(
      generation: event.generation,
      sequence: event.sequence,
      resources: Map.unmodifiable(resources),
      edges: Map.unmodifiable(edges),
      presentations: Map.unmodifiable(presentations),
    );
    _scheduleRefresh();
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

  Future<void> _runRefresh() async {
    if (_disposed || _scopeCounts.isEmpty) return;
    state = state.copyWith(refreshing: true);
    try {
      while (_refreshRequested && !_disposed && _scopeCounts.isNotEmpty) {
        _refreshRequested = false;
        final snapshot = await _fetchSnapshot(_scopeCounts.keys.toList());
        if (_disposed) return;
        if (snapshot.graph.sequence >= (state.sequence ?? 0)) {
          _applySnapshot(snapshot.graph, snapshot.compiledStatuses);
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

  Future<void> _dispose() async {
    _disposed = true;
    await _messages?.cancel();
    await _compiledMessages?.cancel();
    await _lifecycle?.cancel();
    await _subscription?.unsubscribe();
    await _compiledSubscription?.unsubscribe();
  }
}
