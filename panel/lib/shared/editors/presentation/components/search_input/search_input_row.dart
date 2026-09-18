part of "search_input.dart";

/// Renders one presentation search result and keeps the focused row visible.
///
/// The row is read only even when the enclosing editor is writable. Its
/// payload supplies the expression context needed by the presentation
/// renderer, while selection remains an operation of the enclosing input.
/// Unknown payloads use the shared missing renderer instead of being treated
/// as selectable presentation results.
class _PresentationSearchResultRow extends HookWidget {
  const _PresentationSearchResultRow({
    required this.context,
    required this.scope,
    required this.selected,
    required this.onSelect,
    required this.onPointerDown,
    required this.onPointerEnd,
  });

  final SearchResultRowContext context;
  final PresentationRenderScope scope;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerEnd;

  @override
  Widget build(BuildContext buildContext) {
    final payload = context.result.payload;
    if (payload is! PresentationSearchResultPayload) {
      return MissingSearchResultRendererRow(result: context.result);
    }
    final focused = context.focused;
    final background = selected
        ? buildContext.colors.selectionContainer
        : focused
        ? buildContext.colors.surfaceEmphasized
        : Colors.transparent;
    final visibilityKey = useGlobalKey(
      debugLabel: "Search result ${context.result.id}",
    );

    useEffect(() {
      if (!focused) return null;
      var active = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rowContext = visibilityKey.currentContext;
        if (!active || rowContext == null) return;
        Scrollable.ensureVisible(
          rowContext,
          alignment: 0.5,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          duration: MediaQuery.disableAnimationsOf(rowContext)
              ? Duration.zero
              : 180.ms,
          curve: Curves.easeOutCubic,
        );
      });
      return () => active = false;
    }, [focused, visibilityKey]);

    final childScope = scope.copyWith(
      expressions: payload.expressions,
      enabled: true,
      readOnly: true,
    );
    return Semantics(
      key: visibilityKey,
      button: true,
      selected: selected,
      focused: focused,
      label: context.result.title ?? context.result.id,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: buildContext.spacing.space1,
          vertical: 1,
        ),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(buildContext)
              ? Duration.zero
              : 160.ms,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: background,
            borderRadius: buildContext.shapes.mediumBorderRadius,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: buildContext.shapes.mediumBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: Listener(
              onPointerDown: context.loading ? null : (_) => onPointerDown(),
              onPointerUp: context.loading ? null : (_) => onPointerEnd(),
              onPointerCancel: context.loading ? null : (_) => onPointerEnd(),
              child: InkWell(
                overlayColor: buildContext.stateTokens.overlay(
                  buildContext.colors.contentPrimary,
                ),
                onTap: context.loading ? null : onSelect,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: buildContext.spacing.space3,
                    vertical: 10,
                  ),
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DefaultTextStyle.merge(
                        style: selected
                            ? TextStyle(
                                color: buildContext.colors.onSelectionContainer,
                              )
                            : null,
                        child: IconTheme.merge(
                          data: IconThemeData(
                            color: selected
                                ? buildContext.colors.onSelectionContainer
                                : null,
                          ),
                          child: PresentationNodeRenderer(
                            node: payload.presentation,
                            scope: childScope,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders the inactive value summary that activates the search interaction.
///
/// A summary presentation receives a virtual, read only binding containing the
/// current canonical value. It can therefore use the same presentation
/// expressions as an ordinary node without gaining a write path into the
/// editor. Missing and mixed values remain distinct because only mixed input
/// has replacement semantics across several owners.
class _SearchInputSummary extends HookWidget {
  const _SearchInputSummary({
    required this.element,
    required this.binding,
    required this.scope,
    required this.inputController,
    required this.onStartEditing,
    required this.summaryBuilder,
  });

  final SearchInputElement element;
  final InspectedBinding binding;
  final PresentationRenderScope scope;
  final InputFieldController inputController;
  final VoidCallback onStartEditing;
  final PresentationSearchSummaryBuilder? summaryBuilder;

  @override
  Widget build(BuildContext context) {
    final current = binding.value.valueOrNull;
    final mixed = binding.value is MixedEditorValue;
    final presentation = element.summary;
    final summary = mixed
        ? const Text("Multiple values")
        : summaryBuilder?.call(context, current) ??
              (current == null
                  ? const Text("No value")
                  : presentation == null
                  ? Text(current.expressionDisplayText)
                  : PresentationNodeRenderer(
                      node: presentation,
                      scope: scope.withVirtualBinding(
                        VirtualBindingHost(
                          id: element.summaryBindingId,
                          snapshot: BindingSnapshot(
                            type: binding.type,
                            value: current,
                            revision: binding.revision,
                            writable: false,
                          ),
                          onChanged: (_) {},
                        ),
                      ),
                    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputFieldContainer(
          controller: inputController,
          onInputFocus: onStartEditing,
          child: Focus(
            focusNode: inputController.inputFocusNode,
            child: Semantics(
              button: true,
              enabled: scope.enabled && !scope.readOnly && binding.writable,
              label: "Activate search input",
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: inputController.beginInteraction,
                  child: InputDecorator(
                    isEmpty: false,
                    isFocused: inputController.surroundingFocusNode.hasFocus,
                    decoration: const InputDecoration(
                      isDense: true,
                      visualDensity: .comfortable,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.spacing.space3,
                      ),
                      child: IgnorePointer(child: summary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (mixed) const MixedValueMessage(),
      ],
    );
  }
}
