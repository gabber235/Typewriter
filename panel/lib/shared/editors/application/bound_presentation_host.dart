import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef PortableBindingReader = skir.DataValue? Function(skir.ValuePath path);
typedef PortableBindingWriter =
    FutureOr<PortablePresentationWriteResult> Function(
      skir.ValuePath path,
      skir.DataValue value,
    );

typedef PortableBindingItemsWriter =
    FutureOr<PortablePresentationWriteResult> Function(
      skir.ValuePath path,
      List<skir.DataValue> values,
    );

/// Explicitly maps one backend owned editor value into a portable binding.
///
/// The reader and writer are supplied by the feature that owns the backend
/// data transfer object. This adapter never converts a legacy type catalog or
/// infers a nominal schema from runtime values. A binding that stands for
/// several selected items reads each of them through [readItems]. Its value
/// is what they agree on: records and named values of one type agree field by
/// field, and every part they disagree on is unfilled. The snapshot keeps
/// every item's value so controls can tell where they differ.
final class BoundPresentationBinding {
  const BoundPresentationBinding({
    required this.id,
    required this.use,
    required this.read,
    this.readItems,
    this.write,
    this.writeItems,
    this.owner,
    this.control,
  });

  /// A binding that reads [owner] through [read].
  ///
  /// Over a [MultiEditOwner] it reads each selected owner with [read] as well,
  /// so the binding is mixed wherever they disagree, and [write] reaches every
  /// selected owner through the combined owner. With [at], the place in each
  /// owner this binding edits, it also writes a different value to each
  /// selected owner through [writeItems].
  factory BoundPresentationBinding.owned({
    required skir.ExpressionBindingId id,
    required skir.TypeUse use,
    required EditOwner owner,
    required skir.DataValue Function(EditOwner owner) read,
    skir.ValuePath? at,
    PortableBindingWriter? write,
    EditControl? control,
  }) => BoundPresentationBinding(
    id: id,
    use: use,
    owner: owner,
    control: control,
    read: (_) => read(owner),
    readItems: owner is MultiEditOwner
        ? () => [for (final item in owner.owners) read(item)]
        : null,
    write: write,
    writeItems: owner is MultiEditOwner && at != null
        ? (path, values) => owner
              .updateEach(
                skir.ValuePath(segments: [...at.segments, ...path.segments]),
                values,
              )
              .toPortablePresentationResult(binding: id, sourcePath: at)
        : null,
  );

  final skir.ExpressionBindingId id;
  final skir.TypeUse use;
  final PortableBindingReader read;

  /// Reads the value each selected item holds, when the binding stands for
  /// several items.
  final List<skir.DataValue> Function()? readItems;
  final PortableBindingWriter? write;

  /// Writes the value at the same index to each selected item, in the order
  /// [readItems] reads them.
  final PortableBindingItemsWriter? writeItems;

  /// The backend editor source whose changes invalidate this binding.
  final Listenable? owner;
  final EditControl? control;

  bool get editable => write != null;

  /// Each selected item's value when they disagree, otherwise empty.
  List<skir.DataValue> get _disagreeingItems {
    final items = readItems?.call() ?? const <skir.DataValue>[];
    return items.toSet().length > 1 ? List.unmodifiable(items) : const [];
  }

  /// The value a control edits: what the selected items agree on.
  skir.DataValue? get current => switch (_disagreeingItems) {
    [] => read(editorRootPath),
    final items => items.agreement,
  };

  /// Where this binding's value lives in a [BoundPresentationHost]: a
  /// location of its own, so nested controls, collections and actions
  /// address it as they address an authored value.
  skir.ValueLocation get location => skir.ValueLocation(
    resource: skir.ResourceId(value: "bound:${id.value}"),
    path: editorRootPath,
  );

  PortablePresentationBinding snapshot() {
    final items = readItems?.call() ?? const <skir.DataValue>[];
    return PortablePresentationBinding(
      schema: PortablePresentationBindingSchema.complete(use),
      location: location,
      value: items.toSet().length > 1
          ? items.agreement
          : read(editorRootPath) ?? skir.DataValue.unfilled,
      editable: editable,
      itemValues: List.unmodifiable(items),
    );
  }
}

/// Presents backend owned service drafts through the portable renderer.
///
/// Persistence, conflicts, remote refreshes, reservations, and save policy
/// remain on the original editor sources. This host only exposes their current
/// values through explicit feature owned codecs and forwards accepted writes.
/// Every binding has a [BoundPresentationBinding.location], so a write or a
/// list, map or form action addressed through a nested binding reaches the
/// binding that owns it. Actions are applied here to the owning binding's
/// current value and written whole; new items, rows and forms start from the
/// catalog's local defaults. Writes compare their captured invocation value
/// with the current binding before calling the writer. Disposal releases binding controls and observer
/// subscriptions; the feature retains ownership of the underlying draft.
final class BoundPresentationHost extends ChangeNotifier
    implements
        PortablePresentationHost,
        PortableItemsWriteHost,
        PortableCollectionMutationHost {
  BoundPresentationHost({
    required this.catalog,
    required this.root,
    required Iterable<BoundPresentationBinding> bindings,
    required this.budget,
    this._enabled = true,
    this.readOnly = false,
    this.capabilities = const PortablePresentationCapabilities(),
    this.role,
    this.material,
    this.contextInputs,
    this.activePresentations = const {},
    this.slots = const {},
  }) : _bindings = _indexBindings(bindings) {
    _byLocation = {
      for (final binding in _bindings.values)
        binding.location.resource: binding,
    };
    _document = _snapshot();
    for (final owner in _owners) {
      owner.addListener(_changed);
    }
  }

  final CheckedEditorCatalog catalog;
  final skir.PresentationNode Function() root;
  final Map<skir.ExpressionBindingId, BoundPresentationBinding> _bindings;
  late final Map<skir.ResourceId, BoundPresentationBinding> _byLocation;
  final skir.EvaluationBudget budget;
  final skir.PresentationRole? role;
  final skir.PresentationMaterial? material;

  /// Context inputs of a presentation built without material.
  final List<skir.PresentationContextInput>? contextInputs;
  final Set<skir.PresentationId> activePresentations;
  final Map<String, skir.PresentationNode> slots;
  late PortablePresentationDocument _document;
  bool _disposed = false;

  final bool _enabled;

  @override
  bool get enabled => _enabled && !_disposed;

  @override
  final bool readOnly;

  @override
  final PortablePresentationCapabilities capabilities;

  Set<Listenable> get _owners => _bindings.values
      .map((candidate) => candidate.owner)
      .whereType<Listenable>()
      .toSet();

  @override
  PortablePresentationDocument get document => _document;

  /// Returns the existing backend source lifetime behind a binding.
  Listenable? bindingOwner(skir.ExpressionBindingId id) => _bindings[id]?.owner;

  /// The binding [reference] addresses through its location, and the path
  /// within that binding's value.
  (BoundPresentationBinding, skir.ValuePath)? _resolve(
    skir.BindingRef reference,
    PortableInvocationContext context,
  ) {
    final located = location(reference, context: context);
    final binding = located == null ? null : _byLocation[located.resource];
    return binding == null ? null : (binding, located!.path);
  }

  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (!enabled || readOnly) return null;
    return _resolve(reference, context)?.$1.control;
  }

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    return context.read(reference, catalog.snapshot.generation);
  }

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => context.location(reference, catalog.snapshot.generation);

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != catalog.snapshot.generation) return null;
    final exposed = context.bindings[reference.bindingId];
    if (exposed == null) return null;
    final root = switch (exposed.schema) {
      CompletePortablePresentationBinding(:final use) => use,
      _ => null,
    };
    if (root == null) return null;
    if (reference.path.segments.isEmpty) return root;
    final selection = switch (root) {
      skir.TypeUse_namedWrapper(:final value) =>
        skir.TypeSelection.wrapComplete(value),
      _ => null,
    };
    return selection == null
        ? null
        : catalog.valueTypeAt(selection, reference.path, value: exposed.value);
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    final resolved = _resolve(reference, context);
    final rejected = _admit(reference, resolved, [value], context: context);
    if (rejected != null) return rejected;
    final (binding, path) = resolved!;
    return _applied(await binding.write!(path, value));
  }

  @override
  Future<PortablePresentationWriteResult> writeItems(
    skir.BindingRef reference,
    List<skir.DataValue> values, {
    required PortableInvocationContext context,
  }) async {
    final resolved = _resolve(reference, context);
    final writer = resolved?.$1.writeItems;
    if (writer == null) {
      return _reject(
        "This presentation binding cannot write each item",
        target: reference,
      );
    }
    final rejected = _admit(reference, resolved, values, context: context);
    if (rejected != null) return rejected;
    return _applied(await writer(resolved!.$2, values));
  }

  PortablePresentationWriteResult _applied(
    PortablePresentationWriteResult result,
  ) {
    if (result is PortablePresentationWriteApplied && !_disposed) _changed();
    return _located(result);
  }

  /// [result] with each diagnostic aimed at one of this host's bindings aimed
  /// at that binding's location instead, where its control shows it.
  PortablePresentationWriteResult _located(
    PortablePresentationWriteResult result,
  ) => switch (result) {
    PortablePresentationWriteRejected(:final diagnostics) =>
      PortablePresentationWriteResult.rejected([
        for (final diagnostic in diagnostics)
          diagnostic.copyWith(
            targets: [
              for (final target in diagnostic.targets)
                switch (target) {
                  PortableBindingDiagnosticTarget(:final reference)
                      when _bindings[reference.bindingId] != null =>
                    PortableDiagnosticTarget.value(
                      skir.ValueLocation(
                        resource:
                            _bindings[reference.bindingId]!.location.resource,
                        path: reference.path,
                      ),
                    ),
                  _ => target,
                },
            ],
          ),
      ]),
    _ => result,
  };

  /// Why [values] may not be written at [reference], which resolves to
  /// [resolved], or null when they may.
  PortablePresentationWriteResult? _admit(
    skir.BindingRef reference,
    (BoundPresentationBinding, skir.ValuePath)? resolved,
    List<skir.DataValue> values, {
    required PortableInvocationContext context,
  }) {
    if (!enabled || readOnly) {
      return _reject("This presentation is read only", target: reference);
    }
    if (resolved == null || resolved.$1.write == null) {
      return _reject(
        "This presentation binding is read only",
        target: reference,
      );
    }
    final (binding, path) = resolved;
    if (!context.isCurrent(
      reference,
      catalog.snapshot.generation,
      binding.current?.editorValueAt(path),
    )) {
      return _reject(
        "The presentation value changed before this write",
        target: reference,
      );
    }
    final expected = expectedType(reference, context: context);
    if (expected == null ||
        !values.every(
          (value) => catalog.admitsPortableValue(expected, value),
        )) {
      return _reject(
        "The value does not match the binding type",
        target: reference,
      );
    }
    return null;
  }

  @override
  Future<PortablePresentationWriteResult> addCollectionItem(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    return _edit(
      reference,
      context,
      (collection) => collection.withItemAppended(
        skir.ListItem(
          id: item,
          value: _newValue(
            expectedType(
              _child(reference, [skir.PathSegment.createItem(id: item)]),
              context: context,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<PortablePresentationWriteResult> addMapRow(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    final row = skir.ItemId(value: "panel:${const Uuid().v4()}");
    skir.DataValue branch(skir.PathSegment side) => _newValue(
      expectedType(
        _child(reference, [skir.PathSegment.createItem(id: row), side]),
        context: context,
      ),
    );
    return _edit(
      reference,
      context,
      (map) => map.withRows(
        (rows) => [
          ...rows,
          skir.MapRow(
            id: row,
            key: branch(skir.PathSegment.mapKey),
            value: branch(skir.PathSegment.mapValue),
          ),
        ],
      ),
    );
  }

  /// [reference] with [segments] appended to its path.
  skir.BindingRef _child(
    skir.BindingRef reference,
    List<skir.PathSegment> segments,
  ) => skir.BindingRef(
    bindingId: reference.bindingId,
    path: skir.ValuePath(segments: [...reference.path.segments, ...segments]),
  );

  /// The value a new item, row or form of [type] starts with: a concrete
  /// record made of its fields' defaults, or the type's default.
  skir.DataValue _newValue(skir.TypeUse? type) => switch (type) {
    skir.TypeUse_namedWrapper(:final value) =>
      catalog.localRecord(value) ?? catalog.defaultValue(type),
    _ => catalog.defaultValue(type),
  };

  /// Writes what [change] makes of the collection at [reference], read from
  /// the owning binding's current value; an unfilled collection starts empty.
  Future<PortablePresentationWriteResult> _edit(
    skir.BindingRef reference,
    PortableInvocationContext context,
    skir.DataValue? Function(skir.DataValue collection) change,
  ) async {
    final resolved = _resolve(reference, context);
    final current = resolved?.$1.current?.editorValueAt(resolved.$2);
    final collection = current == skir.DataValue.unfilled
        ? catalog.defaultValue(expectedType(reference, context: context))
        : current;
    final replacement = collection == null ? null : change(collection);
    if (replacement == null) {
      return _reject(
        "The collection item is no longer available",
        target: reference,
      );
    }
    return write(reference, replacement, context: context);
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async {
    if (editorAction is skir.EditorAction_navigateWrapper ||
        editorAction is skir.EditorAction_authoringWrapper) {
      final invoke = capabilities.resourceAction;
      if (!enabled ||
          invoke == null ||
          editorAction is skir.EditorAction_authoringWrapper && readOnly) {
        return _reject("This resource action is unavailable");
      }
      return invoke(editorAction, context);
    }
    if (!enabled || readOnly) {
      return _reject("This presentation is read only");
    }
    if (editorAction case skir.EditorAction_localWrapper(:final value)) {
      return _executeLocal(value, context);
    }
    return _reject("This presentation action is unavailable");
  }

  Future<PortablePresentationWriteResult> _executeLocal(
    skir.LocalEditorAction action,
    PortableInvocationContext context,
  ) async {
    skir.DataValue? evaluate(skir.ExpressionNode expression) =>
        switch (PortableExpressionEvaluator.located(
          context.bindings,
          budget: budget,
          catalog: context.queries?.catalog ?? catalog,
          queries: context.queries,
        ).evaluate(expression)) {
          PortableExpressionAvailable(:final value) => value,
          _ => null,
        };
    skir.ListItem item(skir.DataValue value) => skir.ListItem(
      id: skir.ItemId(value: const Uuid().v4()),
      value: value,
    );
    Future<PortablePresentationWriteResult> edit(
      skir.BindingRef target,
      skir.DataValue? Function(skir.DataValue collection) change,
    ) => _edit(target, context, change);
    switch (action) {
      case skir.LocalEditorAction_setValueWrapper(:final value):
        final replacement = evaluate(value.value);
        return replacement == null
            ? _reject("The action value is unavailable", target: value.target)
            : write(value.target, replacement, context: context);
      case skir.LocalEditorAction_insertListItemWrapper(:final value):
        final replacement = evaluate(value.value);
        return edit(
          value.target,
          (list) => replacement == null
              ? null
              : list.withItemAfter(value.after, item(replacement)),
        );
      case skir.LocalEditorAction_appendListItemWrapper(:final value):
        final replacement = evaluate(value.value);
        return edit(
          value.target,
          (list) => replacement == null
              ? null
              : list.withItemAppended(item(replacement)),
        );
      case skir.LocalEditorAction_removeListItemWrapper(:final value):
        return edit(value.target, (list) => list.withoutItem(value.item));
      case skir.LocalEditorAction_duplicateListItemWrapper(:final value):
        return edit(value.target, (list) {
          final source = list.authoredItems
              ?.where((candidate) => candidate.id == value.item)
              .firstOrNull;
          return source == null
              ? null
              : list.withItemAfter(value.item, item(source.value));
        });
      case skir.LocalEditorAction_moveListItemWrapper(:final value):
        return edit(
          value.target,
          (list) => list.withItemMoved(value.item, value.after),
        );
      case skir.LocalEditorAction_insertMapRowWrapper(:final value):
        final key = evaluate(value.key);
        final replacement = evaluate(value.value);
        return edit(
          value.target,
          (map) => key == null || replacement == null
              ? null
              : map.withRows(
                  (rows) => [
                    ...rows,
                    skir.MapRow(
                      id: skir.ItemId(value: const Uuid().v4()),
                      key: key,
                      value: replacement,
                    ),
                  ],
                ),
        );
      case skir.LocalEditorAction_updateMapRowWrapper(:final value):
        final key = evaluate(value.key);
        final replacement = evaluate(value.value);
        return edit(
          value.target,
          (map) => key == null || replacement == null
              ? null
              : map.withRows(
                  (rows) => rows.any((row) => row.id == value.row)
                      ? [
                          for (final row in rows)
                            if (row.id == value.row)
                              skir.MapRow(
                                id: row.id,
                                key: key,
                                value: replacement,
                              )
                            else
                              row,
                        ]
                      : null,
                ),
        );
      case skir.LocalEditorAction_removeMapRowWrapper(:final value):
        return edit(
          value.target,
          (map) => map.withRows(
            (rows) => rows.any((row) => row.id == value.row)
                ? [
                    for (final row in rows)
                      if (row.id != value.row) row,
                  ]
                : null,
          ),
        );
      case skir.LocalEditorAction_chooseFormWrapper(:final value):
        final form = switch (value.type) {
          skir.TypeUse_namedWrapper(value: final named) => catalog.localRecord(
            named,
          ),
          _ => null,
        };
        return form == null
            ? _reject("The selected form cannot be made", target: value.target)
            : write(value.target, form, context: context);
      case skir.LocalEditorAction_unknown():
        return _reject("This local editor action is unavailable");
    }
  }

  PortablePresentationWriteResult _reject(
    String message, {
    skir.BindingRef? target,
  }) => _located(
    PortablePresentationWriteResult.rejected([
      PortablePresentationDiagnostic(
        code: "binding_rejected",
        message: message,
        severity: skir.DiagnosticSeverity.error,
        targets: target == null
            ? const []
            : [PortableDiagnosticTarget.binding(target)],
      ),
    ]),
  );

  PortablePresentationDocument _snapshot() => PortablePresentationDocument(
    catalog: catalog,
    queries: PortableExpressionQueries(catalog: catalog),
    root: root(),
    bindings: {
      for (final entry in _bindings.entries) entry.key: entry.value.snapshot(),
    },
    budget: budget,
    role: role,
    material: material,
    contextInputs: contextInputs,
    activePresentations: activePresentations,
    slots: slots,
  );

  void _changed() {
    if (_disposed) return;
    _document = _snapshot();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final control
        in _bindings.values
            .map((binding) => binding.control)
            .whereType<EditControl>()
            .toSet()) {
      control.dispose();
    }
    for (final owner in _owners) {
      owner.removeListener(_changed);
    }
    super.dispose();
  }
}

Map<skir.ExpressionBindingId, BoundPresentationBinding> _indexBindings(
  Iterable<BoundPresentationBinding> values,
) {
  final indexed = <skir.ExpressionBindingId, BoundPresentationBinding>{};
  for (final value in values) {
    if (indexed.containsKey(value.id)) {
      throw ArgumentError.value(value.id, "bindings", "Duplicate binding id");
    }
    indexed[value.id] = value;
  }
  return Map.unmodifiable(indexed);
}

extension on List<skir.DataValue> {
  /// What these values agree on: the value when they are all equal; a record
  /// or a named value of one type made of what they agree on in each field;
  /// otherwise unfilled.
  skir.DataValue get agreement {
    final first = this.first;
    if (every((value) => value == first)) return first;
    if (first case skir.DataValue_namedWrapper(value: final named)) {
      final payloads = [
        for (final value in this)
          if (value case skir.DataValue_namedWrapper(:final value)
              when value.actualType == named.actualType)
            value.payload,
      ];
      if (payloads.length == length) {
        return skir.DataValue.createNamed(
          actualType: named.actualType,
          payload: payloads.agreement,
        );
      }
    }
    if (first case skir.DataValue_recordWrapper(value: final record)) {
      final names = [for (final field in record.fields) field.name];
      final records = [
        for (final value in this)
          if (value case skir.DataValue_recordWrapper(:final value)
              when listEquals([
                for (final field in value.fields) field.name,
              ], names))
            value,
      ];
      if (records.length == length) {
        return skir.DataValue.createRecord(
          fields: [
            for (final (index, name) in names.indexed)
              skir.FieldValue(
                name: name,
                value: [
                  for (final record in records)
                    record.fields.elementAt(index).value,
                ].agreement,
              ),
          ],
        );
      }
    }
    return skir.DataValue.unfilled;
  }
}
