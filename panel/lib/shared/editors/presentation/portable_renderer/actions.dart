part of "../portable_presentation_renderer.dart";

extension _PortableScopeActions on PortablePresentationScope {
  Future<void> executeAction(skir.EditorAction editorAction) async {
    if (!canExecuteAction) return;
    if (authoring == null && host != null) {
      final portableHost = host!;
      final result = await portableHost.execute(editorAction);
      if (result case PortablePresentationWriteRejected(:final message)) {
        reportStatus?.call(message);
      }
      return;
    }
    try {
      switch (editorAction) {
        case skir.EditorAction_localWrapper(:final value):
          await _executeLocalAction(value);
        case skir.EditorAction_realmWrapper(:final value):
          await _executeRealmAction(value);
        case skir.EditorAction_unknown():
          reportStatus?.call("This editor action is unavailable");
      }
    } on Object catch (error) {
      reportStatus?.call("The editor action did not complete: $error");
    }
  }

  Future<void> _executeLocalAction(skir.LocalEditorAction local) async {
    switch (local) {
      case skir.LocalEditorAction_setValueWrapper(:final value):
        final replacement = _evaluateActionValue(value.value);
        if (replacement != null) _editBinding(value.target, replacement);
      case skir.LocalEditorAction_insertListItemWrapper(:final value):
        final replacement = _evaluateActionValue(value.value);
        if (replacement == null) return;
        _editList(value.target, (location, authored) {
          return authored.insert(
            location,
            value.after,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          );
        }, reads: replacement.reads);
      case skir.LocalEditorAction_appendListItemWrapper(:final value):
        final replacement = _evaluateActionValue(value.value);
        if (replacement == null) return;
        final items = read(value.target)?.authoredItems?.toList();
        if (items == null) {
          reportStatus?.call("The action target is not a collection");
          return;
        }
        _editList(value.target, (location, authored) {
          return authored.insert(
            location,
            items.lastOrNull?.id,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          );
        }, reads: replacement.reads);
      case skir.LocalEditorAction_removeListItemWrapper(:final value):
        _editList(
          value.target,
          (location, authored) => authored.remove(location, value.item),
        );
      case skir.LocalEditorAction_duplicateListItemWrapper(:final value):
        final collectionLocation = location(value.target);
        final items = read(value.target)?.authoredItems?.toList();
        final source = items
            ?.where((candidate) => candidate.id == value.item)
            .firstOrNull;
        if (collectionLocation == null || source == null) {
          reportStatus?.call("The collection item is no longer available");
          return;
        }
        _editList(
          value.target,
          (location, authored) {
            return authored.insert(
              location,
              source.id,
              skir.ListItem(
                id: skir.ItemId(value: const Uuid().v4()),
                value: source.value,
              ),
            );
          },
          reads: [
            PortableExpressionRead(
              value.target.bindingId,
              skir.ValuePath(
                segments: [
                  ...value.target.path.segments,
                  skir.PathSegment.createItem(id: source.id),
                ],
              ),
              location: skir.ValueLocation(
                resource: collectionLocation.resource,
                path: skir.ValuePath(
                  segments: [
                    ...collectionLocation.path.segments,
                    skir.PathSegment.createItem(id: source.id),
                  ],
                ),
              ),
            ),
          ],
        );
      case skir.LocalEditorAction_moveListItemWrapper(:final value):
        _editList(
          value.target,
          (location, authored) =>
              authored.move(location, value.item, value.after),
        );
      case skir.LocalEditorAction_insertMapRowWrapper(:final value):
        final key = _evaluateActionValue(value.key);
        final replacement = _evaluateActionValue(value.value);
        if (key == null || replacement == null) return;
        _editMap(
          value.target,
          (rows) => [
            ...rows,
            skir.MapRow(
              id: skir.ItemId(value: const Uuid().v4()),
              key: key.value,
              value: replacement.value,
            ),
          ],
          reads: [...key.reads, ...replacement.reads],
        );
      case skir.LocalEditorAction_updateMapRowWrapper(:final value):
        final key = _evaluateActionValue(value.key);
        final replacement = _evaluateActionValue(value.value);
        if (key == null || replacement == null) return;
        _editMap(
          value.target,
          (rows) => [
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
          requiredRow: value.row,
          reads: [...key.reads, ...replacement.reads],
        );
      case skir.LocalEditorAction_removeMapRowWrapper(:final value):
        _editMap(
          value.target,
          (rows) => rows.where((row) => row.id != value.row).toList(),
          requiredRow: value.row,
        );
      case skir.LocalEditorAction_chooseFormWrapper(:final value):
        await _chooseForm(value);
      case skir.LocalEditorAction_unknown():
        reportStatus?.call("This local editor action is unavailable");
    }
  }

  Future<void> _executeRealmAction(skir.RealmEditorAction realm) async {
    switch (realm) {
      case skir.RealmEditorAction_reloadWrapper():
        final callback = reload;
        if (callback == null) {
          reportStatus?.call("Reload is unavailable");
          return;
        }
        await callback();
      case skir.RealmEditorAction_commandWrapper(:final value):
        final callback = invokeCommand;
        if (callback == null) {
          reportStatus?.call("Realm commands are unavailable");
          return;
        }
        final payload = _evaluateActionValue(value.payload);
        if (payload != null) {
          await callback(value.capabilityId, payload.value);
        }
      case skir.RealmEditorAction_unknown():
        reportStatus?.call("This Realm editor action is unavailable");
    }
  }

  _EvaluatedActionValue? _evaluateActionValue(skir.ExpressionNode node) {
    final result = evaluate(node);
    return switch (result) {
      PortableExpressionAvailable(:final value, :final reads) =>
        _EvaluatedActionValue(value, reads),
      PortableExpressionUnavailable() => _reportActionFailure(
        "The action needs values that are not available",
      ),
      PortableExpressionFailed(:final message) => _reportActionFailure(message),
    };
  }

  void _editBinding(skir.BindingRef target, _EvaluatedActionValue replacement) {
    final location = this.location(target);
    final authored = authoring;
    if (location == null || authored == null) {
      reportStatus?.call("The action target is unavailable");
      return;
    }
    stage("Edit value", (operation) {
      operation
        ..observeExpressionReads(replacement.reads)
        ..set(location, replacement.value);
    });
  }

  _EvaluatedActionValue? _reportActionFailure(String message) {
    reportStatus?.call(message);
    return null;
  }

  void _editList(
    skir.BindingRef target,
    PortablePathResult<skir.AuthoringRecord> Function(
      skir.ValueLocation location,
      PortableAuthoringEdit draft,
    )
    edit, {
    Iterable<PortableExpressionRead> reads = const [],
  }) {
    final location = this.location(target);
    final authored = authoring;
    if (location == null || authored == null) {
      reportStatus?.call("The action target is unavailable");
      return;
    }
    stage("Edit collection", (operation) {
      operation.observeExpressionReads(reads);
      edit(location, operation);
    });
  }

  void _editMap(
    skir.BindingRef target,
    List<skir.MapRow> Function(List<skir.MapRow> rows) update, {
    skir.ItemId? requiredRow,
    Iterable<PortableExpressionRead> reads = const [],
  }) {
    final location = this.location(target);
    final authored = authoring;
    final current = read(target)?.authoredPayload;
    if (location == null || authored == null) {
      reportStatus?.call("The action target is unavailable");
      return;
    }
    if (current is! skir.DataValue_mapValueWrapper) {
      reportStatus?.call("The action target is not a map");
      return;
    }
    final rows = current.value.rows.toList();
    if (requiredRow != null && rows.every((row) => row.id != requiredRow)) {
      reportStatus?.call("The map row is no longer available");
      return;
    }
    stage("Edit map", (operation) {
      operation.observeExpressionReads(reads);
      final latest = operation.expect(location);
      if (latest is! PortablePathValue<skir.DataValue> ||
          latest.value.authoredPayload != current) {
        throw StateError("The map changed before this action");
      }
      operation.replaceMap(location, update(rows));
    });
  }

  Future<void> _chooseForm(skir.ChooseFormAction choice) async {
    final location = this.location(choice.target);
    final authored = authoring;
    final prepare = prepareCreation;
    final named = switch (choice.type) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    if (location == null ||
        authored == null ||
        prepare == null ||
        named == null) {
      reportStatus?.call("The selected form cannot be prepared");
      return;
    }
    final operation = const Uuid().v4();
    final request = skir.InitializationRequest(
      id: skir.InitializationRequestId(value: "panel:form:$operation"),
      catalog: authored.generation,
      type: skir.TypeSelection.wrapComplete(named),
      supplied: const [],
      intentHash: sha256
          .convert(
            utf8.encode(
              "${authored.generation.value}\u0000${location.resource.value}\u0000${_pathLabel(location.path)}\u0000$named",
            ),
          )
          .toString(),
    );
    try {
      final previousFindingCount = authored.initializationFindings.length;
      final result = await this.prepare("Choose form", (operation) async {
        operation.expect(location);
        final prepared = await prepare(request);
        operation.applyPreparedRecord(location, request, prepared);
      });
      if (result is AuthoringEditRejected) return;
      final findings =
          (edit?.document.initializationFindings ??
                  const <skir.InitializationDiagnostic>[])
              .skip(previousFindingCount);
      if (findings.isNotEmpty) {
        reportStatus?.call(
          findings.map(formatPortableInitializationDiagnostic).join("\n"),
        );
      }
    } on Object catch (error) {
      reportStatus?.call("The selected form could not be prepared: $error");
    }
  }
}

final class _EvaluatedActionValue {
  const _EvaluatedActionValue(this.value, this.reads);

  final skir.DataValue value;
  final List<PortableExpressionRead> reads;
}

extension _PortableActionRendering on PortablePresentationNodeRenderer {
  Widget _renderCommitControls(PortablePresentationScope childScope) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: FilledButton(
      onPressed:
          childScope.enabled &&
              !childScope.readOnly &&
              childScope.commit != null
          ? childScope.commit
          : null,
      child: const Text("Save"),
    ),
  );

  Widget _renderButton(
    skir.ButtonElement button,
    PortablePresentationScope childScope,
  ) {
    final label = _string(childScope, button.label);
    return switch (label) {
      _ResolvedValue(:final value) => HookBuilder(
        builder: (context) {
          final states = useWidgetStatesController();
          return FilledButton(
            statesController: states,
            onPressed: childScope.canExecuteAction
                ? () => unawaited(childScope.executeAction(button.action))
                : null,
            child: ValueListenableBuilder<Set<WidgetState>>(
              valueListenable: states,
              builder: (context, observed, _) => PresentationInteractionScope(
                value: PresentationInteraction.fromWidgetStates(observed),
                child: Text(value),
              ),
            ),
          );
        },
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderIconButton(
    skir.IconButtonElement button,
    PortablePresentationScope childScope,
  ) {
    final icon = _string(childScope, button.icon);
    final label = _string(childScope, button.semanticLabel);
    if (icon is _ResolvedFailure<String>) return _diagnostic(icon.message);
    if (label is _ResolvedFailure<String>) return _diagnostic(label.message);
    return IconButton(
      tooltip: (label as _ResolvedValue<String>).value,
      onPressed: childScope.canExecuteAction
          ? () => unawaited(childScope.executeAction(button.action))
          : null,
      icon: Icon(_materialIcon((icon as _ResolvedValue<String>).value)),
    );
  }

  Widget _renderMenu(
    skir.MenuElement menu,
    PortablePresentationScope childScope,
  ) {
    final items = <({String id, String label, skir.EditorAction action})>[];
    for (final item in menu.items) {
      final label = _string(childScope, item.label);
      if (label case _ResolvedValue<String>(:final value)) {
        items.add((id: item.itemId, label: value, action: item.action));
      }
    }
    if (items.isEmpty) {
      return _diagnostic("The menu has no available actions");
    }
    final label = menu.label == null ? null : _string(childScope, menu.label!);
    return PopupMenuButton<String>(
      enabled: childScope.canExecuteAction,
      tooltip: switch (label) {
        _ResolvedValue<String>(:final value) => value,
        _ => "Open menu",
      },
      onSelected: (id) {
        final item = items.where((candidate) => candidate.id == id).firstOrNull;
        if (item != null) unawaited(childScope.executeAction(item.action));
      },
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem(value: item.id, child: Text(item.label)),
      ],
    );
  }
}
