part of "../portable_presentation_renderer.dart";

extension _PortableLinkInputRendering on PortablePresentationNodeRenderer {
  Widget _renderLinkInput(
    BuildContext context,
    skir.LinkControl control,
    PortablePresentationScope childScope,
  ) {
    final location = childScope.location(control.control.binding);
    final draft = childScope.authoring;
    final catalog = childScope.catalog;
    if (location == null || draft == null || catalog == null) {
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
        scope: childScope,
        location: location,
        candidates: candidates,
        candidateDefinition: candidateDefinition,
      );
    }
    final rows = [
      for (final (index, item) in items.indexed)
        _AuthoredLinkValueInput(
          key: ValueKey("${node.nodeId}.link.${item.id.value}"),
          control: control,
          scope: childScope,
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
          showPrefix: false,
          leading: control.allowReorder
              ? _AuthoredReorderHandle(
                  index: index,
                  label: "Reorder linked resource ${index + 1}",
                  enabled: childScope.enabled && !childScope.readOnly,
                  canMoveEarlier: index > 0,
                  canMoveLater: index < items.length - 1,
                  onMoveEarlier: () {
                    final after = index == 1 ? null : items[index - 2].id;
                    childScope.stage("Edit collection", (operation) {
                      operation.move(location, item.id, after);
                    });
                  },
                  onMoveLater: () {
                    childScope.stage("Edit collection", (operation) {
                      operation.move(location, item.id, items[index + 1].id);
                    });
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
              childScope.stage("Edit collection", (operation) {
                operation.move(location, moving, after);
              });
            },
          )
        : Column(children: rows);
    return _controlFrame(
      control.control,
      childScope,
      _withControlPrefix(
        control.control,
        childScope,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            list,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
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
                icon: const Icon(Icons.add_link),
                label: const Text("Add link"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AuthoredLinkValueInput extends StatelessWidget {
  const _AuthoredLinkValueInput({
    required this.control,
    required this.scope,
    required this.location,
    required this.candidates,
    required this.candidateDefinition,
    this.framed = true,
    this.showPrefix = true,
    this.leading,
    super.key,
  });

  final skir.LinkControl control;
  final PortablePresentationScope scope;
  final skir.ValueLocation location;
  final Map<skir.ResourceId, _AuthoredCollectionRow>? candidates;
  final skir.PresentationCollectionDefinition? candidateDefinition;
  final bool framed;
  final bool showPrefix;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final record = scope.authoring?.resource(location.resource);
    final value = record == null
        ? null
        : switch (record.readAt(location.path)) {
            PortablePathValue(value: final value) => value,
            PortablePathUnavailable() => null,
          };
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
                ? "No resource selected"
                : _authoredLinkTargetLabel(
                        scope.authoring?.resource(link.target.resource),
                      ) ??
                      link.target.resource.value,
            overflow: TextOverflow.ellipsis,
          );
    final content = DepthBox(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space2),
        child: Row(
          children: [
            ?leading,
            if (leading != null) SizedBox(width: context.spacing.space2),
            if (showPrefix) ?_controlPrefix(control.control, scope),
            if (showPrefix && control.control.prefix != null)
              SizedBox(width: context.spacing.space2),
            Expanded(child: summary),
            IconButton(
              tooltip: link == null
                  ? "Choose linked resource"
                  : "Change linked resource",
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
              icon: Icon(link == null ? Icons.link : Icons.edit_outlined),
            ),
            if (link != null)
              IconButton(
                tooltip: "Clear link",
                onPressed: enabled
                    ? () {
                        scope.stage("Clear link", (operation) {
                          operation.disconnect(
                            skir.LinkOccurrence(
                              id: skir.LinkOccurrenceId(
                                endpoint: link.endpoint,
                                location: location,
                              ),
                              source: location.resource,
                              target: link.target,
                            ),
                          );
                        });
                      }
                    : null,
                icon: const Icon(Icons.link_off),
              ),
          ],
        ),
      ),
    );
    return framed ? _controlFrame(control.control, scope, content) : content;
  }
}
