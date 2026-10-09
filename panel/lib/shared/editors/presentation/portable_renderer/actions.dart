part of "../portable_presentation_renderer.dart";

extension _PortableScopeActions on PortablePresentationScope {
  Future<void> executeAction(skir.EditorAction editorAction) async {
    final target = host;
    if (!canExecuteAction || target == null) return;
    final result = await target.execute(editorAction, context: invocation);
    if (result case PortablePresentationWriteRejected(:final message)) {
      reportStatus?.call(message);
    }
  }

  void moveListItem(
    skir.BindingRef target,
    skir.ItemId item,
    skir.ItemId? after,
  ) => unawaited(
    executeAction(
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createMoveListItem(
          target: target,
          item: item,
          after: after,
        ),
      ),
    ),
  );

  void removeListItem(skir.BindingRef target, skir.ItemId item) => unawaited(
    executeAction(
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createRemoveListItem(target: target, item: item),
      ),
    ),
  );

  void removeMapRow(skir.BindingRef target, skir.ItemId row) => unawaited(
    executeAction(
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createRemoveMapRow(target: target, row: row),
      ),
    ),
  );

  Future<void> addCollectionItem(skir.BindingRef reference) async {
    final target = host;
    if (!canExecuteAction || target == null) return;
    if (target is! PortableCollectionMutationHost) return;
    final collectionTarget = target as PortableCollectionMutationHost;
    final result = await collectionTarget.addCollectionItem(
      reference,
      context: invocation,
    );
    if (result case PortablePresentationWriteRejected(:final message)) {
      reportStatus?.call(message);
    }
  }

  void addMapRow(skir.BindingRef reference) {
    final target = host;
    if (!canExecuteAction || target == null) return;
    if (target is! PortableCollectionMutationHost) return;
    final collectionTarget = target as PortableCollectionMutationHost;
    final result = collectionTarget.addMapRow(reference, context: invocation);
    if (result case PortablePresentationWriteRejected(:final message)) {
      reportStatus?.call(message);
    }
  }
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
