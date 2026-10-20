part of "../portable_presentation_renderer.dart";

extension _PortableLinkInputRendering on PortablePresentationNodeRenderer {
  Widget _renderLinkInput(
    BuildContext context,
    skir.LinkControl control,
    PortablePresentationScope childScope, {
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
  }) {
    final location = childScope.location(control.control.binding);
    final catalog = childScope.catalog;
    if (location == null || catalog == null) {
      return _diagnostic("The link control binding is unavailable");
    }
    Map<skir.ResourceId, _AuthoredCollectionRow>? candidates;
    skir.PresentationCollectionDefinition? candidateDefinition;
    if (control.sourceId case final sourceId?) {
      final collection = _authoredCollection(sourceId, childScope);
      if (collection.problem != null) {
        return _diagnostic(collection.problem!);
      }
      candidateDefinition = collection.definition;
      candidates = {
        for (final row in collection.rows)
          if (row.selectable) row.resource: row,
      };
    }
    final items = childScope
        .read(control.control.binding)
        ?.authoredItems
        ?.toList(growable: false);
    if (items == null) {
      return _AuthoredLinkValueInput(
        key: ValueKey("${node.nodeId}.link"),
        control: control,
        owner: node,
        scope: childScope,
        reference: control.control.binding,
        location: location,
        candidates: candidates,
        candidateDefinition: candidateDefinition,
      );
    }
    final rowControl =
        (control.toMutable()
              ..control = (control.control.toMutable()..prefix = null)
                  .toFrozen())
            .toFrozen();
    return collectionWithFocus(
      sourceScope: childScope,
      mutationScope: childScope,
      reference: control.control.binding,
      removalKind: _CollectionRemovalKind.none,
      renderedOrder: [for (final item in items) item.id],
      sourceHeader: node.header == null
          ? null
          : _ScopedCollectionHeader(header: node.header, scope: childScope),
      fallbackHeader: () => (_generatedEntryHeader(
        childScope.associationFor(control.control).label ?? "Linked resources",
      ).toMutable()..initiallyExpanded = true).toFrozen(),
      contained: true,
      allowAdd: true,
      content: control.content,
      addLabel: "Add link",
      addIcon: Icons.add_link,
      add: (context) => unawaited(
        _addSequenceItem(
          context: context,
          control: control.control,
          linkControl: control,
          collection: location,
          childScope: childScope,
        ),
      ),
      headerBuilder: headerBuilder,
      buildBody: (context) {
        late final CollectionSequence sequence;
        sequence = CollectionSequence(
          scope: childScope,
          collection: control.control.binding,
          items: items,
          allowReorder: control.allowReorder,
          entryBuilder: (context, item, index) {
            final reference = skir.BindingRef(
              bindingId: control.control.binding.bindingId,
              path: skir.ValuePath(
                segments: [
                  ...control.control.binding.path.segments,
                  skir.PathSegment.createItem(id: item.id),
                ],
              ),
            );
            final itemLocation = skir.ValueLocation(
              resource: location.resource,
              path: skir.ValuePath(
                segments: [
                  ...location.path.segments,
                  skir.PathSegment.createItem(id: item.id),
                ],
              ),
            );
            return directLinkEntry(
              item: item,
              reference: reference,
              location: itemLocation,
              scope: childScope,
              owner: node,
              control: rowControl,
              candidates: candidates,
              candidateDefinition: candidateDefinition,
              fallbackHeader: () => _generatedEntryHeader("Item ${index + 1}"),
              movementControls: [
                if (control.allowReorder)
                  _SuppliedHeaderControl(
                    command: _CollectionCommand.reorder(
                      childScope.diagnosticTarget(reference),
                    ),
                    build: (context) => sequence.handle(
                      context,
                      index,
                      childScope,
                      label: "Reorder linked resource ${index + 1}",
                      icon: _operationGlyph(
                        control.content?.reorderIcon,
                        childScope,
                        const Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
        return _controlFrame(
          control.control,
          control.inputAppearance == null
              ? childScope
              : childScope.withAppearance(control.inputAppearance!),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty)
                _collectionEmpty(
                  context,
                  childScope,
                  control.content,
                  "No linked resources",
                ),
              sequence,
            ],
          ),
          renderPrefix: true,
        );
      },
    );
  }
}

extension _DirectLinkCollectionRow on PortablePresentationNodeRenderer {
  Widget directLinkEntry({
    required skir.ListItem item,
    required skir.BindingRef reference,
    required skir.ValueLocation location,
    required PortablePresentationScope scope,
    required skir.PresentationNode owner,
    required skir.LinkControl control,
    required Map<skir.ResourceId, _AuthoredCollectionRow>? candidates,
    required skir.PresentationCollectionDefinition? candidateDefinition,
    required List<_SuppliedHeaderControl> movementControls,
    required skir.PresentationHeader Function() fallbackHeader,
  }) {
    final address = scope.authoredAliases.resolve(reference);
    if (address == null) return _diagnostic("The linked item is unavailable");
    return _MountedCollectionRow(
      key: ValueKey(item.id.value),
      row: item.id,
      builder: (context, row) {
        final style = _controlStyle(context, scope, control.inputAppearance);
        final link = scope.read(reference)?.authoredLink;
        final enabled = scope.canExecuteAction;
        final selectedRow = link == null
            ? null
            : candidates?[link.target.resource];
        final summary = link == null
            ? Text(
                _entryPlaceholder(control.inputContent, scope) ??
                    _operationText(
                      scope,
                      control.content?.emptyText,
                      "No resource selected",
                    ),
                overflow: TextOverflow.ellipsis,
              )
            : _ResourceReferenceAppearance(
                resource: link.target.resource,
                scope: selectedRow?.scope ?? scope,
                role: skir.PresentationRole.referencePreview,
                render: (node, targetScope, _) =>
                    PortablePresentationNodeRenderer(
                      node: node,
                      scope: targetScope,
                    ),
                fallback: (appearance, problem) => Text(
                  problem ?? appearance?.label ?? link.target.resource.value,
                ),
              );
        final identityAndChoose = InputDecorator(
          decoration: style.decoration.copyWith(enabled: enabled),
          child: DefaultTextStyle.merge(
            style: style.valueStyle,
            child: Padding(
              padding: style.padding ?? EdgeInsets.all(context.spacing.space2),
              child: Row(
                children: [
                  ?_entryLeading(
                    context,
                    control.control,
                    control.inputContent,
                    scope,
                    style,
                    Icons.link,
                  ),
                  if (control.inputContent?.leading != skir.InputAdornment.none)
                    SizedBox(width: context.spacing.space2),
                  Expanded(child: summary),
                  ?_entrySuffix(control.inputContent, scope),
                  _operationAppearance(
                    control.content,
                    scope,
                    (states, buttonStyle) => IconButton(
                      focusNode: row.recoveryFocus,
                      statesController: states,
                      style: buttonStyle,
                      tooltip: _operationText(
                        scope,
                        control.content?.operationTooltip ??
                            control.content?.chooseLabel,
                        link == null
                            ? "Choose linked resource"
                            : "Change linked resource",
                      ),
                      onPressed: enabled
                          ? () => runDirectLinkChange(
                              context: context,
                              scope: scope,
                              control: control,
                              location: location,
                              candidates: candidates,
                              candidateDefinition: candidateDefinition,
                            )
                          : null,
                      icon: _operationGlyph(
                        control.content?.chooseIcon,
                        scope,
                        Icon(link == null ? Icons.link : Icons.edit_outlined),
                      ),
                    ),
                    tooltip: false,
                  ),
                ],
              ),
            ),
          ),
        );
        final clear = link == null
            ? null
            : directLinkClearControl(
                row: row,
                scope: scope,
                control: control,
                reference: reference,
                occurrence: skir.LinkOccurrence(
                  id: skir.LinkOccurrenceId(
                    endpoint: link.endpoint,
                    location: location,
                  ),
                  source: location.resource,
                  target: link.target,
                ),
              );
        return _CollectionEntry(
          editor: _CollectionEditorContinuation(
            owner: address,
            scope: scope,
            layout: CollectionEntryLayout.inline,
            render: (context, _) => identityAndChoose,
          ),
          controls: [...movementControls, ?clear],
          generatedHeader: fallbackHeader,
          initiallyNeedsRepair: false,
          scope: scope,
          owner: owner,
          appearance: control.appearance,
        );
      },
    );
  }
}

extension CollectionLinkOperations on PortablePresentationScope {
  /// Disconnects both relation ends through the host and retains operation feedback.
  /// A source collection occurrence is removed by the relation transaction.
  Future<void> clearLinkedOccurrence({
    required skir.BindingRef reference,
    required skir.LinkOccurrence occurrence,
    VoidCallback? onApplied,
  }) async {
    final linkHost = switch (host) {
      final PortableLinkHost value => value,
      _ => null,
    };
    if (!canExecuteAction || linkHost == null) return;
    final address = diagnosticTarget(reference);
    await operations.run(
      key: PortableOperationKey.write(address),
      input: PortableDiagnosticObservation(
        target: address,
        value: read(reference),
      ),
      onApplied: onApplied,
      operation: () => linkHost.disconnectLink(occurrence, context: invocation),
    );
  }
}

extension _DirectLinkCollectionOperations on PortablePresentationNodeRenderer {
  void runDirectLinkChange({
    required BuildContext context,
    required PortablePresentationScope scope,
    required skir.LinkControl control,
    required skir.ValueLocation location,
    required Map<skir.ResourceId, _AuthoredCollectionRow>? candidates,
    required skir.PresentationCollectionDefinition? candidateDefinition,
  }) {
    _CollectionInteractionScope.invalidateAncestors(context);
    unawaited(
      _chooseLink(
        context: context,
        scope: scope,
        control: control,
        location: location,
        candidates: candidates,
        candidateDefinition: candidateDefinition,
      ),
    );
  }

  _SuppliedHeaderControl directLinkClearControl({
    required _CollectionRowBinding row,
    required PortablePresentationScope scope,
    required skir.LinkControl control,
    required skir.BindingRef reference,
    required skir.LinkOccurrence occurrence,
  }) => _SuppliedHeaderControl(
    command: _CollectionCommand.disconnect(occurrence),
    build: (context) => _operationAppearance(
      control.content,
      scope,
      (states, style) => IconButton(
        statesController: states,
        style: style,
        tooltip: _operationText(
          scope,
          control.content?.operationTooltip ?? control.content?.unlinkLabel,
          "Clear link",
        ),
        onPressed: scope.canExecuteAction && scope.host is PortableLinkHost
            ? () => runCollectionClear(
                row: row,
                scope: scope,
                reference: reference,
                occurrence: occurrence,
              )
            : null,
        icon: _operationGlyph(
          control.content?.unlinkIcon,
          scope,
          const Icon(Icons.link_off),
        ),
      ),
      tooltip: false,
    ),
  );
}

final class _AuthoredLinkValueInput extends StatelessWidget {
  const _AuthoredLinkValueInput({
    required this.control,
    required this.owner,
    required this.scope,
    required this.reference,
    required this.location,
    required this.candidates,
    required this.candidateDefinition,
    super.key,
  });

  final skir.LinkControl control;
  final skir.PresentationNode owner;
  final PortablePresentationScope scope;
  final skir.BindingRef reference;
  final skir.ValueLocation location;
  final Map<skir.ResourceId, _AuthoredCollectionRow>? candidates;
  final skir.PresentationCollectionDefinition? candidateDefinition;

  @override
  Widget build(BuildContext context) {
    final style = _controlStyle(context, scope, control.inputAppearance);
    final value = scope.read(reference);
    final link = value?.authoredLink;
    final enabled = scope.enabled && !scope.readOnly;
    final selectedRow = link == null ? null : candidates?[link.target.resource];
    final summary = link == null
        ? Text(
            _entryPlaceholder(control.inputContent, scope) ??
                _operationText(
                  scope,
                  control.content?.emptyText,
                  "No resource selected",
                ),
            overflow: TextOverflow.ellipsis,
          )
        : _ResourceReferenceAppearance(
            resource: link.target.resource,
            scope: selectedRow?.scope ?? scope,
            role: skir.PresentationRole.referencePreview,
            render: (node, targetScope, _) => PortablePresentationNodeRenderer(
              node: node,
              scope: targetScope,
            ),
            fallback: (appearance, problem) => Text(
              problem ?? appearance?.label ?? link.target.resource.value,
            ),
          );
    final content = InputDecorator(
      decoration: style.decoration.copyWith(enabled: enabled),
      child: DefaultTextStyle.merge(
        style: style.valueStyle,
        child: Padding(
          padding: style.padding ?? EdgeInsets.all(context.spacing.space2),
          child: Row(
            children: [
              ?_entryLeading(
                context,
                control.control,
                control.inputContent,
                scope,
                style,
                Icons.link,
              ),
              if (control.inputContent?.leading != skir.InputAdornment.none)
                SizedBox(width: context.spacing.space2),
              Expanded(child: summary),
              ?_entrySuffix(control.inputContent, scope),
              _operationAppearance(
                control.content,
                scope,
                (states, style) => IconButton(
                  statesController: states,
                  style: style,
                  tooltip: _operationText(
                    scope,
                    control.content?.operationTooltip ??
                        control.content?.chooseLabel,
                    link == null
                        ? "Choose linked resource"
                        : "Change linked resource",
                  ),
                  onPressed: enabled
                      ? () => _chooseLink(
                          context: context,
                          scope: scope,
                          control: control,
                          location: location,
                          candidates: candidates,
                          candidateDefinition: candidateDefinition,
                        )
                      : null,
                  icon: _operationGlyph(
                    control.content?.chooseIcon,
                    scope,
                    Icon(link == null ? Icons.link : Icons.edit_outlined),
                  ),
                ),
                tooltip: false,
              ),
              if (link != null)
                _operationAppearance(
                  control.content,
                  scope,
                  (states, style) => IconButton(
                    statesController: states,
                    style: style,
                    tooltip: _operationText(
                      scope,
                      control.content?.operationTooltip ??
                          control.content?.unlinkLabel,
                      "Clear link",
                    ),
                    onPressed: enabled
                        ? () {
                            unawaited(
                              scope.clearLinkedOccurrence(
                                reference: reference,
                                occurrence: skir.LinkOccurrence(
                                  id: skir.LinkOccurrenceId(
                                    endpoint: link.endpoint,
                                    location: location,
                                  ),
                                  source: location.resource,
                                  target: link.target,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: _operationGlyph(
                      control.content?.unlinkIcon,
                      scope,
                      const Icon(Icons.link_off),
                    ),
                  ),
                  tooltip: false,
                ),
            ],
          ),
        ),
      ),
    );
    final framedContent = _controlFrame(
      control.control,
      control.inputAppearance == null
          ? scope
          : scope.withAppearance(control.inputAppearance!),
      content,
    );
    if (_CollectionInlineEditor.contains(context)) return framedContent;
    return Padding(
      padding: EdgeInsets.only(
        bottom: _collectionSpacing(context, control.appearance),
      ),
      child: _collectionSurface(
        context,
        control.appearance,
        scope,
        owner,
        Padding(
          padding: control.appearance?.itemPadding == null
              ? EdgeInsets.zero
              : _presentationInsets(control.appearance!.itemPadding),
          child: framedContent,
        ),
      ),
    );
  }
}
