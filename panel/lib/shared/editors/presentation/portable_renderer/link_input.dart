part of "../portable_presentation_renderer.dart";

extension _PortableLinkInputRendering on PortablePresentationNodeRenderer {
  Widget _renderLinkInput(
    BuildContext context,
    skir.LinkControl control,
    PortablePresentationScope childScope,
  ) {
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
    final current = childScope.read(control.control.binding);
    final items = current?.authoredItems?.toList(growable: false);
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
    final rows = [
      for (final (index, item) in items.indexed)
        _AuthoredLinkValueInput(
          key: ValueKey("${node.nodeId}.link.${item.id.value}"),
          control: rowControl,
          owner: node,
          scope: childScope,
          reference: skir.BindingRef(
            bindingId: control.control.binding.bindingId,
            path: skir.ValuePath(
              segments: [
                ...control.control.binding.path.segments,
                skir.PathSegment.createItem(id: item.id),
              ],
            ),
          ),
          location: skir.ValueLocation(
            resource: location.resource,
            path: skir.ValuePath(
              segments: [
                ...location.path.segments,
                skir.PathSegment.createItem(id: item.id),
              ],
            ),
          ),
          candidates: candidates,
          candidateDefinition: candidateDefinition,
          framed: false,
          showPrefix: true,
          leading: control.allowReorder
              ? _AuthoredReorderHandle(
                  index: index,
                  label: "Reorder linked resource ${index + 1}",
                  icon: _operationGlyph(
                    control.content?.reorderIcon,
                    childScope,
                    const Icon(Icons.drag_handle),
                  ),
                  enabled: childScope.enabled && !childScope.readOnly,
                  canMoveEarlier: index > 0,
                  canMoveLater: index < items.length - 1,
                  onMoveEarlier: () {
                    final after = index == 1 ? null : items[index - 2].id;
                    childScope.moveListItem(
                      control.control.binding,
                      item.id,
                      after,
                    );
                  },
                  onMoveLater: () {
                    childScope.moveListItem(
                      control.control.binding,
                      item.id,
                      items[index + 1].id,
                    );
                  },
                )
              : null,
        ),
    ];
    final list = control.allowReorder
        ? ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: rows.length,
            itemBuilder: (_, index) => rows[index],
            onReorderItem: (oldIndex, newIndex) {
              if (!childScope.enabled || childScope.readOnly) return;
              final moving = items[oldIndex].id;
              final remaining = [...items]..removeAt(oldIndex);
              final after = newIndex == 0 ? null : remaining[newIndex - 1].id;
              childScope.moveListItem(control.control.binding, moving, after);
            },
          )
        : Column(children: rows);
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
          list,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _operationAppearance(
              control.content,
              childScope,
              (states, style) => TextButton.icon(
                statesController: states,
                onPressed: childScope.enabled && !childScope.readOnly
                    ? () async {
                        final item = skir.ItemId(
                          value: "panel:${const Uuid().v4()}",
                        );
                        await _chooseLink(
                          context: context,
                          scope: childScope,
                          control: control,
                          location: skir.ValueLocation(
                            resource: location.resource,
                            path: skir.ValuePath(
                              segments: [
                                ...location.path.segments,
                                skir.PathSegment.createItem(id: item),
                              ],
                            ),
                          ),
                          candidates: candidates,
                          candidateDefinition: candidateDefinition,
                        );
                      }
                    : null,
                style: style,
                icon: _operationGlyph(
                  control.content?.addIcon,
                  childScope,
                  const Icon(Icons.add_link),
                ),
                label: Text(
                  _operationText(
                    childScope,
                    control.content?.addLabel,
                    "Add link",
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      renderPrefix: true,
    );
  }
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
    this.framed = true,
    this.showPrefix = true,
    this.leading,
    super.key,
  });

  final skir.LinkControl control;
  final skir.PresentationNode owner;
  final PortablePresentationScope scope;
  final skir.BindingRef reference;
  final skir.ValueLocation location;
  final Map<skir.ResourceId, _AuthoredCollectionRow>? candidates;
  final skir.PresentationCollectionDefinition? candidateDefinition;
  final bool framed;
  final bool showPrefix;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final style = _controlStyle(context, scope, control.inputAppearance);
    final value = scope.read(reference);
    final link = value?.authoredLink;
    final enabled = scope.enabled && !scope.readOnly;
    final selectedRow = link == null ? null : candidates?[link.target.resource];
    final summary = selectedRow != null && candidateDefinition != null
        ? _AuthoredCollectionRowAppearance(
            row: selectedRow,
            definition: candidateDefinition!,
          )
        : Text(
            link == null
                ? _entryPlaceholder(control.inputContent, scope) ??
                      _operationText(
                        scope,
                        control.content?.emptyText,
                        "No resource selected",
                      )
                : switch (scope.host) {
                    final PortableCollectionProjectionHost host =>
                      host
                              .projectResource(
                                link.target.resource,
                                context: scope.invocation,
                              )
                              ?.label ??
                          link.target.resource.value,
                    _ => link.target.resource.value,
                  },
            overflow: TextOverflow.ellipsis,
          );
    final content = InputDecorator(
      decoration: style.decoration.copyWith(enabled: enabled),
      child: DefaultTextStyle.merge(
        style: style.valueStyle,
        child: Padding(
          padding: style.padding ?? EdgeInsets.all(context.spacing.space2),
          child: Row(
            children: [
              ?leading,
              if (leading != null) SizedBox(width: context.spacing.space2),
              if (showPrefix)
                ?_entryLeading(
                  context,
                  control.control,
                  control.inputContent,
                  scope,
                  style,
                  Icons.link,
                ),
              if (showPrefix &&
                  control.inputContent?.leading != skir.InputAdornment.none)
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
                            final linkHost = switch (scope.host) {
                              final PortableLinkHost value => value,
                              _ => null,
                            };
                            if (linkHost == null) return;
                            final address = scope.diagnosticTarget(reference);
                            unawaited(
                              scope.operations.run(
                                key: PortableOperationKey.write(address),
                                input: PortableDiagnosticObservation(
                                  target: address,
                                  value: scope.read(reference),
                                ),
                                operation: () => linkHost.disconnectLink(
                                  skir.LinkOccurrence(
                                    id: skir.LinkOccurrenceId(
                                      endpoint: link.endpoint,
                                      location: location,
                                    ),
                                    source: location.resource,
                                    target: link.target,
                                  ),
                                  context: scope.invocation,
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
    final framedContent = framed
        ? _controlFrame(
            control.control,
            control.inputAppearance == null
                ? scope
                : scope.withAppearance(control.inputAppearance!),
            content,
          )
        : content;
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
