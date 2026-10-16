part of "../portable_presentation_renderer.dart";

@freezed
abstract class _RemovalFocusIntent with _$RemovalFocusIntent {
  const factory _RemovalFocusIntent({
    required Object token,
    required skir.ItemId row,
    required FocusNode origin,
    required Set<FocusNode> fallbackScopes,
    required int index,
    @Default(false) bool applied,
    @Default(false) bool observedRemoval,
    @Default(false) bool recoveryQueued,
  }) = __RemovalFocusIntent;
}

// One instance per mounted collection identity and host ownership.
// The mounted collection and rows own their FocusNodes.
class _CollectionRemovalFocus {
  _CollectionRemovalFocus({
    required this.isCurrent,
    required this.currentOrder,
    required this.rowHasFocus,
    required this.recoveryFocusFor,
    required this.addFocus,
    required this.removalForRow,
    required this.targetForRow,
  }) {
    FocusManager.instance.addListener(_onFocusChanged);
  }

  final bool Function() isCurrent;
  // Read current live source membership, including before a frame rebuild.
  // Return null for an unavailable or replaced owner, never an empty list.
  final List<skir.ItemId>? Function() currentOrder;
  final bool Function(skir.ItemId) rowHasFocus;
  final FocusNode? Function(skir.ItemId) recoveryFocusFor;
  final FocusNode addFocus;
  // Created from the canonical containing collection address and row ID.
  // Return null if generic Remove does not belong to this collection.
  final _CollectionCommand? Function(skir.ItemId) removalForRow;
  final PortableDiagnosticTarget? Function(skir.ItemId) targetForRow;
  _RemovalFocusIntent? _pending;
  Object _generation = Object();
  bool _disposed = false;

  Future<void> removeLocal({
    required skir.ItemId row,
    required PortablePresentationScope scope,
    required skir.EditorAction action,
    required _CollectionActionOrigin? origin,
  }) async {
    final actual = scope.collectionRemovalCommand(action);
    final expected = removalForRow(row);
    final matching =
        actual != null &&
        actual == expected &&
        (actual is _RemoveListCommand || actual is _RemoveMapCommand);
    if (!matching) {
      // Preserve all authored actions, but do not arm collection recovery
      // for resource deletion, navigation or another collection target.
      invalidateInteraction();
      await scope.executeAction(action);
      return;
    }
    await _observeLocalRemoval(
      row: row,
      scope: scope,
      origin: origin,
      invoke: (onApplied) => scope.executeAction(action, onApplied: onApplied),
    );
  }

  Future<void> clearLink({
    required skir.ItemId row,
    required PortablePresentationScope scope,
    required skir.BindingRef reference,
    required skir.LinkOccurrence occurrence,
    required _CollectionActionOrigin? origin,
  }) async {
    final expected = targetForRow(row);
    final location = scope.location(reference);
    if (expected == null ||
        location == null ||
        location != occurrence.id.location ||
        scope.diagnosticTarget(reference) != expected) {
      invalidateInteraction();
      await scope.clearLinkedOccurrence(
        reference: reference,
        occurrence: occurrence,
      );
      return;
    }
    await _observeLocalRemoval(
      row: row,
      scope: scope,
      origin: origin,
      invoke: (onApplied) => scope.clearLinkedOccurrence(
        reference: reference,
        occurrence: occurrence,
        onApplied: onApplied,
      ),
    );
  }

  Future<void> _observeLocalRemoval({
    required skir.ItemId row,
    required PortablePresentationScope scope,
    required Future<void> Function(VoidCallback) invoke,
    required _CollectionActionOrigin? origin,
  }) async {
    if (_disposed || !isCurrent() || !scope.canExecuteAction) return;
    // Null means the original action did not own row focus. Never
    // acquire a new origin after a popup or confirmation has closed.
    final captured = origin;
    final order = currentOrder();
    final index = order?.indexOf(row) ?? -1;
    if (captured == null ||
        captured.row != row ||
        index < 0 ||
        !_canArmOrigin(captured)) {
      invalidateInteraction();
      await invoke(() {});
      return;
    }
    final token = captured.token;
    _pending = _RemovalFocusIntent(
      token: token,
      row: row,
      origin: captured.origin,
      fallbackScopes: captured.fallbackScopes,
      index: index,
    );
    try {
      await invoke(() {
        if (_disposed || _pending?.token != token) return;
        if (!isCurrent()) {
          invalidateInteraction();
          return;
        }
        _pending = _pending!.copyWith(applied: true);
        _finishIfRemoved();
      });
    } finally {
      if (!_disposed && _pending?.token == token && !_pending!.applied) {
        invalidateInteraction();
      }
    }
  }

  void observeRows(List<skir.ItemId> order) {
    if (_disposed || _pending == null) return;
    if (!isCurrent()) {
      invalidateInteraction();
      return;
    }
    final pending = _pending!;
    if (!order.contains(pending.row)) {
      _pending = pending.copyWith(observedRemoval: true);
    } else if (pending.observedRemoval) {
      // Reappearance, including rollback, cancels queued recovery.
      invalidateInteraction();
      return;
    }
    _finishIfRemoved();
  }

  void _onFocusChanged() {
    if (_disposed || _pending == null) return;
    if (!isCurrent()) {
      invalidateInteraction();
      return;
    }
    final pending = _pending!;
    final current = FocusManager.instance.primaryFocus;
    final order = currentOrder();
    if (current == pending.origin) return;
    final fallback =
        current == null || pending.fallbackScopes.contains(current);
    // A different live control always wins, even after row removal.
    // A fallback only remains eligible if the live source row vanished.
    if (!fallback || order == null || order.contains(pending.row)) {
      invalidateInteraction();
    }
  }

  void _finishIfRemoved() {
    final pending = _pending;
    if (pending == null ||
        !pending.applied ||
        !pending.observedRemoval ||
        pending.recoveryQueued) {
      return;
    }
    // Keep observing focus until the scheduled recovery actually runs.
    _pending = pending.copyWith(recoveryQueued: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed ||
          _generation != pending.token ||
          _pending?.token != pending.token ||
          !isCurrent()) {
        return;
      }
      final order = currentOrder();
      if (order == null || order.contains(pending.row)) return;
      final current = FocusManager.instance.primaryFocus;
      if (current != null &&
          current != pending.origin &&
          !pending.fallbackScopes.contains(current)) {
        return;
      }
      final next = order.isEmpty
          ? null
          : order[pending.index.clamp(0, order.length - 1)];
      final candidate = next == null ? null : recoveryFocusFor(next);
      final target =
          candidate != null &&
              candidate.context != null &&
              candidate.canRequestFocus
          ? candidate
          : addFocus;
      _pending = null;
      if (target.context != null && target.canRequestFocus) {
        target.requestFocus();
      }
    });
  }

  _CollectionActionOrigin? captureOrigin(skir.ItemId row) {
    if (_disposed || !isCurrent()) return null;
    invalidateInteraction();
    final origin = FocusManager.instance.primaryFocus;
    if (origin == null || !rowHasFocus(row)) return null;
    return _CollectionActionOrigin(
      token: _generation,
      row: row,
      origin: origin,
      fallbackScopes: {
        for (final ancestor in origin.ancestors)
          if (ancestor is FocusScopeNode) ancestor,
      },
    );
  }

  bool matchesLocalRemoval(
    skir.ItemId row,
    PortablePresentationScope scope,
    skir.EditorAction action,
  ) {
    final actual = scope.collectionRemovalCommand(action);
    return actual != null &&
        actual == removalForRow(row) &&
        (actual is _RemoveListCommand || actual is _RemoveMapCommand);
  }

  bool _canArmOrigin(_CollectionActionOrigin origin) {
    if (_disposed || !isCurrent() || origin.token != _generation) return false;
    final current = FocusManager.instance.primaryFocus;
    return current == null ||
        current == origin.origin ||
        origin.fallbackScopes.contains(current);
  }

  void invalidateInteraction() {
    _generation = Object();
    _pending = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    FocusManager.instance.removeListener(_onFocusChanged);
    invalidateInteraction();
  }
}

// Uses the existing host document abstraction for both authored and bound
// sources. Capture a canonical root reference, never an item scope snapshot.
@freezed
abstract class _LiveCollectionSource with _$LiveCollectionSource {
  const factory _LiveCollectionSource({
    required PortablePresentationHost host,
    required skir.BindingRef source,
    required AuthoredBindingAddress owner,
    required skir.CatalogGeneration generation,
    required Object? lifetime,
  }) = __LiveCollectionSource;
  const _LiveCollectionSource._();

  static _LiveCollectionSource? capture(
    PortablePresentationScope scope,
    skir.BindingRef reference,
  ) {
    final host = scope.host;
    final source = scope.sourceReference(reference);
    final owner = scope.authoredAliases.resolve(reference);
    final generation = scope.catalog?.snapshot.generation;
    if (host == null || source == null || owner == null || generation == null) {
      return null;
    }
    return _LiveCollectionSource(
      host: host,
      source: source,
      owner: owner,
      generation: generation,
      lifetime: scope.nativeSourceIdentity(reference),
    );
  }

  List<skir.ItemId>? currentOrder() {
    if (!host.enabled) return null;
    // An absent authored resource can make document unavailable. Focus
    // recovery is optional and does not turn that state into an empty list.
    final PortablePresentationDocument document;
    try {
      document = host.document;
    } on StateError {
      return null;
    }
    if (document.catalog.snapshot.generation != generation) return null;
    final root = document.bindings[source.bindingId];
    if (root == null) return null;
    final value = root.value.editorValueAt(source.path);
    if (value == null) return null;
    if (value == skir.DataValue.unfilled) return const [];
    return switch (value.authoredPayload) {
      skir.DataValue_listValueWrapper(:final value) => [
        for (final item in value.items) item.id,
      ],
      skir.DataValue_setValueWrapper(:final value) => [
        for (final item in value.items) item.id,
      ],
      skir.DataValue_mapValueWrapper(:final value) => [
        for (final row in value.rows) row.id,
      ],
      _ => null,
    };
  }
}

// Both existing hosts expose current source values through document.
// Do not call host.read with the old invocation snapshot for membership.
@freezed
abstract class _CollectionActionOrigin with _$CollectionActionOrigin {
  const factory _CollectionActionOrigin({
    required Object token,
    required skir.ItemId row,
    required FocusNode origin,
    required Set<FocusNode> fallbackScopes,
  }) = __CollectionActionOrigin;
}

enum _CollectionRemovalKind { listItem, mapRow, none }

// This wraps the owned collection header and its sequence/map body. It is
// keyed by canonical collection owner, not values, validity or width.
class _MountedCollectionInteraction extends StatefulWidget {
  const _MountedCollectionInteraction({
    required this.scope,
    required this.reference,
    required this.removalKind,
    required this.renderedOrder,
    required this.builder,
    super.key,
  });
  final PortablePresentationScope scope;
  final skir.BindingRef reference;
  final _CollectionRemovalKind removalKind;
  final List<skir.ItemId> renderedOrder;
  final WidgetBuilder builder;

  @override
  State<_MountedCollectionInteraction> createState() =>
      _MountedCollectionInteractionState();
}

class _MountedCollectionInteractionState
    extends State<_MountedCollectionInteraction> {
  final addFocus = FocusNode();
  final rows = <skir.ItemId, _CollectionRowBinding>{};
  _LiveCollectionSource? source;
  _CollectionRemovalFocus? focus;
  ModalRoute<dynamic>? route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentRoute = ModalRoute.of(context);
    if (route != null && route != currentRoute) focus?.invalidateInteraction();
    route = currentRoute;
    _updateOwner();
  }

  @override
  void didUpdateWidget(covariant _MountedCollectionInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateOwner();
  }

  void _updateOwner() {
    final next = _LiveCollectionSource.capture(widget.scope, widget.reference);
    if (next == source && focus != null) return;
    focus?.dispose();
    source = next;
    if (next == null) {
      focus = null;
      return;
    }
    focus = _CollectionRemovalFocus(
      isCurrent: () =>
          mounted &&
          source == next &&
          identical(widget.scope.host, next.host) &&
          widget.scope.authoredAliases.resolve(widget.reference) ==
              next.owner &&
          widget.scope.nativeSourceIdentity(widget.reference) ==
              next.lifetime &&
          (route?.isCurrent ?? true) &&
          next.host.enabled,
      currentOrder: next.currentOrder,
      rowHasFocus: (row) => rows[row]?.rowFocus.hasFocus ?? false,
      recoveryFocusFor: (row) => rows[row]?.preferredRecovery,
      addFocus: addFocus,
      removalForRow: (row) {
        final target = widget.scope.collectionCommandTarget(widget.reference);
        if (target == null) return null;
        return switch (widget.removalKind) {
          _CollectionRemovalKind.listItem => _CollectionCommand.removeList(
            target,
            row,
          ),
          _CollectionRemovalKind.mapRow => _CollectionCommand.removeMap(
            target,
            row,
          ),
          _CollectionRemovalKind.none => null,
        };
      },
      targetForRow: (row) {
        final reference = skir.BindingRef(
          bindingId: widget.reference.bindingId,
          path: skir.ValuePath(
            segments: [
              ...widget.reference.path.segments,
              skir.PathSegment.createItem(id: row),
            ],
          ),
        );
        return widget.scope.location(reference) == null
            ? null
            : widget.scope.diagnosticTarget(reference);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    focus?.observeRows(widget.renderedOrder);
    return _CollectionInteractionScope(
      owner: this,
      child: Builder(builder: widget.builder),
    );
  }

  @override
  void dispose() {
    focus?.dispose();
    addFocus.dispose();
    // Each row disposes its own nodes after unregistering.
    super.dispose();
  }
}

class _CollectionInteractionScope extends InheritedWidget {
  const _CollectionInteractionScope({
    required this.owner,
    required super.child,
  });
  final _MountedCollectionInteractionState owner;
  static _MountedCollectionInteractionState of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CollectionInteractionScope>()!
      .owner;
  static void invalidateAncestors(BuildContext context) {
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is _CollectionInteractionScope) {
        widget.owner.focus?.invalidateInteraction();
      }
      return true;
    });
  }

  @override
  bool updateShouldNotify(_CollectionInteractionScope oldWidget) => true;
}

class _CollectionRowBinding {
  _CollectionRowBinding(this.owner, this.row);
  final _MountedCollectionInteractionState owner;
  final skir.ItemId row;
  final rowFocus = FocusNode(canRequestFocus: false, skipTraversal: true);
  final disclosureFocus = FocusNode();
  final recoveryFocus = FocusNode();
  FocusNode? get preferredRecovery {
    for (final node in [disclosureFocus, recoveryFocus]) {
      if (node.context != null && node.canRequestFocus) return node;
    }
    return null;
  }

  _CollectionRemovalFocus? get focus => owner.focus;
  void dispose() {
    rowFocus.dispose();
    disclosureFocus.dispose();
    recoveryFocus.dispose();
  }
}

class _MountedCollectionRow extends StatefulWidget {
  const _MountedCollectionRow({
    required this.row,
    required this.builder,
    super.key,
  });
  final skir.ItemId row;
  final Widget Function(BuildContext, _CollectionRowBinding) builder;
  @override
  State<_MountedCollectionRow> createState() => _MountedCollectionRowState();
}

class _MountedCollectionRowState extends State<_MountedCollectionRow> {
  _CollectionRowBinding? binding;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBinding();
  }

  @override
  void didUpdateWidget(covariant _MountedCollectionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateBinding();
  }

  void _updateBinding() {
    final owner = _CollectionInteractionScope.of(context);
    if (binding?.owner == owner && binding?.row == widget.row) return;
    _release();
    binding = _CollectionRowBinding(owner, widget.row);
    owner.rows[widget.row] = binding!;
  }

  void _release() {
    final previous = binding;
    if (previous == null) return;
    if (identical(previous.owner.rows[previous.row], previous)) {
      previous.owner.rows.remove(previous.row);
    }
    previous.dispose();
    binding = null;
  }

  @override
  Widget build(BuildContext context) => _CollectionRowContext(
    binding: binding!,
    child: Focus(
      focusNode: binding!.rowFocus,
      child: Builder(builder: (context) => widget.builder(context, binding!)),
    ),
  );
  @override
  void dispose() {
    _release();
    super.dispose();
  }
}

class _CollectionRowContext extends InheritedWidget {
  const _CollectionRowContext({required this.binding, required super.child});
  final _CollectionRowBinding binding;
  static _CollectionRowBinding? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CollectionRowContext>()
      ?.binding;
  @override
  bool updateShouldNotify(_CollectionRowContext oldWidget) =>
      binding != oldWidget.binding || binding.focus != oldWidget.binding.focus;
}
