part of "authored_presentation_host.dart";

/// Portable actions: local value edits, Realm commands and form choices.
extension _AuthoredPresentationActions on AuthoredPresentationHost {
  Future<PortablePresentationWriteResult> _execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async {
    if (editorAction is skir.EditorAction_navigateWrapper ||
        editorAction is skir.EditorAction_authoringWrapper ||
        editorAction is skir.EditorAction_createWrapper) {
      if (!enabled ||
          context.catalogGeneration != authored.generation ||
          editorAction is! skir.EditorAction_navigateWrapper &&
              (readOnly || edit == null)) {
        return _reject("This resource action is unavailable");
      }
      final invoke = capabilities.resourceAction;
      return invoke == null
          ? _reject("Resource actions are unavailable")
          : await invoke(editorAction, context);
    }
    if (!enabled || readOnly || edit == null) {
      return _reject("This presentation is read only");
    }
    if (context.catalogGeneration != authored.generation) {
      return _reject("The editor catalog changed");
    }
    try {
      return switch (editorAction) {
        skir.EditorAction_localWrapper(:final value) => await _executeLocal(
          value,
          context,
        ),
        skir.EditorAction_realmWrapper(:final value) => await _executeRealm(
          value,
          context,
        ),
        skir.EditorAction_navigateWrapper() ||
        skir.EditorAction_authoringWrapper() ||
        skir.EditorAction_createWrapper() => _reject(
          "Resource actions are unavailable",
        ),
        skir.EditorAction_unknown() => _reject(
          "This editor action is unavailable",
        ),
      };
    } on Object catch (error) {
      return _reject("The editor action did not complete: $error");
    }
  }

  Future<PortablePresentationWriteResult> _executeLocal(
    skir.LocalEditorAction local,
    PortableInvocationContext context,
  ) async {
    switch (local) {
      case skir.LocalEditorAction_setValueWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        return replacement == null
            ? _reject(
                "The action value is unavailable",
                target: location(value.target, context: context),
              )
            : _stage(
                "Edit value",
                (operation) {
                  final target = location(value.target, context: context);
                  if (target == null) {
                    throw StateError("The action target is unavailable");
                  }
                  operation
                    ..observeExpressionReads(replacement.reads)
                    ..set(target, replacement.value);
                },
                target: location(value.target, context: context),
                from: _observation(context),
              );
      case skir.LocalEditorAction_insertListItemWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        if (replacement == null) {
          return _reject(
            "The action value is unavailable",
            target: location(value.target, context: context),
          );
        }
        return _editList(
          value.target,
          context,
          reads: replacement.reads,
          apply: (target, operation) => operation.insert(
            target,
            value.after,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          ),
        );
      case skir.LocalEditorAction_appendListItemWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        final items = read(value.target, context: context)?.authoredItems;
        if (replacement == null || items == null) {
          return _reject(
            "The action target is not a collection",
            target: location(value.target, context: context),
          );
        }
        return _editList(
          value.target,
          context,
          reads: replacement.reads,
          apply: (target, operation) => operation.insert(
            target,
            items.lastOrNull?.id,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          ),
        );
      case skir.LocalEditorAction_removeListItemWrapper(:final value):
        return _editList(
          value.target,
          context,
          apply: (target, operation) => operation.remove(target, value.item),
        );
      case skir.LocalEditorAction_duplicateListItemWrapper(:final value):
        final target = location(value.target, context: context);
        final source = read(value.target, context: context)?.authoredItems
            ?.where((candidate) => candidate.id == value.item)
            .firstOrNull;
        if (target == null || source == null) {
          return _reject(
            "The collection item is no longer available",
            target: location(value.target, context: context),
          );
        }
        return _editList(
          value.target,
          context,
          reads: [
            skir.ValueLocation(
              resource: target.resource,
              path: skir.ValuePath(
                segments: [
                  ...target.path.segments,
                  skir.PathSegment.createItem(id: source.id),
                ],
              ),
            ),
          ],
          apply: (location, operation) => operation.insert(
            location,
            source.id,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: source.value,
            ),
          ),
        );
      case skir.LocalEditorAction_moveListItemWrapper(:final value):
        return _editList(
          value.target,
          context,
          apply: (target, operation) =>
              operation.move(target, value.item, value.after),
        );
      case skir.LocalEditorAction_insertMapRowWrapper(:final value):
        final key = _evaluate(value.key, context);
        final replacement = _evaluate(value.value, context);
        if (key == null || replacement == null) {
          return _reject(
            "The action value is unavailable",
            target: location(value.target, context: context),
          );
        }
        return _editMap(
          value.target,
          context,
          reads: [...key.reads, ...replacement.reads],
          update: (rows) => [
            ...rows,
            skir.MapRow(
              id: skir.ItemId(value: const Uuid().v4()),
              key: key.value,
              value: replacement.value,
            ),
          ],
        );
      case skir.LocalEditorAction_updateMapRowWrapper(:final value):
        final key = _evaluate(value.key, context);
        final replacement = _evaluate(value.value, context);
        if (key == null || replacement == null) {
          return _reject(
            "The action value is unavailable",
            target: location(value.target, context: context),
          );
        }
        return _editMap(
          value.target,
          context,
          requiredRow: value.row,
          reads: [...key.reads, ...replacement.reads],
          update: (rows) => [
            for (final row in rows)
              if (row.id == value.row)
                skir.MapRow(
                  id: row.id,
                  key: key.value,
                  value: replacement.value,
                )
              else
                row,
          ],
        );
      case skir.LocalEditorAction_removeMapRowWrapper(:final value):
        return _editMap(
          value.target,
          context,
          requiredRow: value.row,
          update: (rows) => rows
              .where((candidate) => candidate.id != value.row)
              .toList(growable: false),
        );
      case skir.LocalEditorAction_chooseFormWrapper(:final value):
        return _chooseForm(value, context);
      case skir.LocalEditorAction_unknown():
        return _reject("This local editor action is unavailable");
    }
  }

  Future<PortablePresentationWriteResult> _executeRealm(
    skir.RealmEditorAction realm,
    PortableInvocationContext context,
  ) async {
    await executePortableRealmAction(
      realm,
      evaluate: (expression) {
        final payload = _evaluate(expression, context);
        if (payload == null) {
          throw StateError("The Realm action payload is unavailable");
        }
        return payload.value;
      },
      invokeCommand: capabilities.invokeCommand,
      reload: capabilities.reload,
    );
    return const PortablePresentationWriteApplied();
  }

  _AuthoredActionValue? _evaluate(
    skir.ExpressionNode expression,
    PortableInvocationContext context,
  ) => switch (PortableExpressionEvaluator.located(
    context.bindings,
    budget: budget,
    catalog: context.queries?.catalog ?? authored.catalog,
    queries: context.queries,
  ).evaluate(expression)) {
    PortableExpressionAvailable(:final value, :final reads) =>
      _AuthoredActionValue(value, reads),
    PortableExpressionUnavailable() || PortableExpressionFailed() => null,
  };

  PortablePresentationWriteResult _editList(
    skir.BindingRef reference,
    PortableInvocationContext context, {
    required PortablePathResult<skir.AuthoringRecord> Function(
      skir.ValueLocation target,
      PortableAuthoringEdit operation,
    )
    apply,
    Iterable<skir.ValueLocation> reads = const [],
  }) {
    final target = location(reference, context: context);
    if (target == null) {
      return _reject("The action target is unavailable", target: target);
    }
    return _stage(
      "Edit collection",
      (operation) {
        operation.observeExpressionReads(reads);
        apply(target, operation);
      },
      target: target,
      from: _observation(context),
    );
  }

  PortablePresentationWriteResult _editMap(
    skir.BindingRef reference,
    PortableInvocationContext context, {
    required List<skir.MapRow> Function(List<skir.MapRow> rows) update,
    skir.ItemId? requiredRow,
    Iterable<skir.ValueLocation> reads = const [],
  }) {
    final target = location(reference, context: context);
    final current = read(reference, context: context)?.authoredPayload;
    if (target == null || current is! skir.DataValue_mapValueWrapper) {
      return _reject("The action target is not a map", target: target);
    }
    final rows = current.value.rows.toList();
    if (requiredRow != null && rows.every((row) => row.id != requiredRow)) {
      return _reject("The map row is no longer available", target: target);
    }
    return _stage(
      "Edit map",
      (operation) {
        operation.observeExpressionReads(reads);
        final latest = operation.expect(target);
        if (latest is! PortablePathValue<skir.DataValue> ||
            latest.value.authoredPayload != current) {
          throw StateError("The map changed before this action");
        }
        operation.replaceMap(target, update(rows));
      },
      target: target,
      from: _observation(context),
    );
  }

  Future<PortablePresentationWriteResult> _chooseForm(
    skir.ChooseFormAction choice,
    PortableInvocationContext context,
  ) async {
    final target = location(choice.target, context: context);
    final prepare = prepareValue;
    final named = switch (choice.type) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    if (target == null || prepare == null || named == null) {
      return _reject("The selected form cannot be prepared", target: target);
    }
    final request = skir.ValuePreparationRequest(
      catalog: authored.generation,
      target: skir.PreparationTarget.wrapRecord(
        skir.TypeSelection.wrapComplete(named),
      ),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
    );
    final binding = edit!;
    final result = await binding.prepare(
      label: "Choose form",
      from: authored,
      apply: (operation) async {
        operation.expect(target);
        final prepared = await prepare(request);
        operation.applyPreparedRecord(target, request, prepared);
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
      },
    );
    if (result case EditStageRejected(:final message)) {
      return _reject(message, target: target);
    }
    return const PortablePresentationWriteApplied();
  }

  /// The current operation owns the write, but expectations belong to the read observation.
  AuthoringDocument _observation(PortableInvocationContext context) =>
      switch (context.queries?.authored) {
        final AuthoringDocument document => document,
        null => authored,
        _ => throw StateError(
          "The authored query observation cannot own edit expectations",
        ),
      };
}
