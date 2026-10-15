import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_presentation_renderer.freezed.dart";
part "portable_renderer/actions.dart";
part "portable_renderer/appearance.dart";
part "portable_renderer/collection_inputs.dart";
part "portable_renderer/collections.dart";
part "portable_renderer/collection_graph_projection.dart";
part "portable_renderer/content.dart";
part "portable_renderer/control_frame.dart";
part "portable_renderer/control_appearance.dart";
part "portable_renderer/control_editing.dart";
part "portable_renderer/operation_results.dart";
part "portable_renderer/diagnostic_tree.dart";
part "portable_renderer/diagnostic_placement.dart";
part "portable_renderer/diagnostic_chrome.dart";
part "portable_renderer/delegation.dart";
part "portable_renderer/expression_resolution.dart";
part "portable_renderer/header.dart";
part "portable_renderer/header_layout.dart";
part "portable_renderer/layout.dart";
part "portable_renderer/link_input.dart";
part "portable_renderer/link_selection.dart";
part "portable_renderer/pages.dart";
part "portable_renderer/reorder_handle.dart";
part "portable_renderer/scalar_inputs.dart";
part "portable_renderer/scope.dart";
part "portable_renderer/structured_inputs.dart";
part "portable_renderer/style.dart";
part "portable_search_input.dart";

final class PortablePresentationNodeRenderer extends StatelessWidget {
  const PortablePresentationNodeRenderer({
    required this.node,
    required this.scope,
    this.fillAvailableSpace = false,
    super.key,
  });

  final skir.PresentationNode node;
  final PortablePresentationScope scope;
  final bool fillAvailableSpace;

  @override
  Widget build(BuildContext context) {
    if (PortableDiagnosticScope.maybeOf(context) == null) {
      return _PortableDiagnosticBoundary(
        key: ValueKey(
          scope.catalog?.snapshot.generation ??
              scope.host?.document.catalog.snapshot.generation,
        ),
        operations: scope.operations,
        diagnostics: scope.host?.document.diagnostics ?? const [],
        observations:
            scope.host?.document.diagnosticObservations ??
            scope.diagnosticObservations,
        child: PortablePresentationChrome(
          role: scope.role,
          child: PortablePresentationNodeRenderer(
            node: node,
            scope: scope,
            fillAvailableSpace: fillAvailableSpace,
          ),
        ),
      );
    }
    final enabled = _boolean(scope, node.properties.enabledIf, fallback: true);
    if (scope.authoredIndex == null) {
      return PortablePresentationNodeRenderer(
        node: node,
        scope: scope.withAuthoredLayout(node),
        fillAvailableSpace: fillAvailableSpace,
      );
    }
    if (enabled case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final available = (enabled as _ResolvedValue<bool>).value;
    final childScope = scope
        .withReadOnly(node.properties.readOnly)
        .withEnabled(available);
    final element = node.element;
    if (element == null) {
      return _diagnostic("The presentation node has no element");
    }
    try {
      return _renderNode(context, element, childScope, available);
    } on PresentationColorFailure catch (failure) {
      return _diagnostic(failure.message);
    } on FormatException catch (failure) {
      return _diagnostic(failure.message);
    }
  }

  Widget _renderNode(
    BuildContext context,
    skir.PresentationElement element,
    PortablePresentationScope childScope,
    bool available, {
    Widget? renderedContent,
  }) {
    final rendered =
        renderedContent ?? _renderElement(context, element, childScope);
    var child = node.header == null
        ? rendered
        : _AuthoredPresentationHeader(
            header: node.header!,
            contained: element is skir.PresentationElement_sectionWrapper,
            body: rendered,
            scope: childScope,
          );
    if (element case skir.PresentationElement_sectionWrapper(:final value)) {
      child = _decorateSection(context, value, childScope, child);
    }
    return Semantics(
      container: true,
      enabled: available,
      child: IgnorePointer(
        ignoring: !available,
        child: AnimatedOpacity(
          opacity: available ? 1 : 0.55,
          duration: const Duration(milliseconds: 120),
          child: KeyedSubtree(key: ValueKey(node.nodeId), child: child),
        ),
      ),
    );
  }

  Widget _renderElement(
    BuildContext context,
    skir.PresentationElement element,
    PortablePresentationScope childScope,
  ) => switch (element) {
    skir.PresentationElement_childrenWrapper(:final value) => _renderChildren(
      value,
      childScope,
      fillAvailableSpace: fillAvailableSpace,
    ),
    skir.PresentationElement_slotWrapper(:final value) => _renderSlot(
      value,
      childScope,
    ),
    skir.PresentationElement_conditionalWrapper(:final value) =>
      _renderConditional(value, childScope),
    skir.PresentationElement_repeatedWrapper(:final value) => _renderRepeated(
      value,
      childScope,
    ),
    skir.PresentationElement_textWrapper(:final value) => _renderText(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_markdownWrapper(:final value) => _renderMarkdown(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_iconWrapper(:final value) => _renderIcon(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_imageWrapper(:final value) => _renderImage(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_badgeWrapper(:final value) => _renderBadge(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_chipWrapper(:final value) => _renderChip(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_progressWrapper(:final value) => _renderProgress(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_statusWrapper(:final value) => _renderStatus(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_dateTimeWrapper(:final value) => _renderDateTime(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_relativeTimeWrapper(:final value) =>
      _renderRelativeTime(context, value, childScope),
    skir.PresentationElement_tabsWrapper(:final value) => _AuthoredTabs(
      tabs: value,
      scope: childScope,
    ),
    skir.PresentationElement_typedFieldWrapper(:final value) =>
      _renderTypedField(value, childScope),
    skir.PresentationElement_scopedBindingWrapper(:final value) =>
      _renderScopedBinding(value, childScope),
    skir.PresentationElement_collectionLookupWrapper(:final value) =>
      _renderCollectionLookup(value, childScope),
    skir.PresentationElement_collectionGraphWrapper(:final value) =>
      _renderCollectionGraph(value, childScope),
    skir.PresentationElement_textInputWrapper(:final value) => _renderTextInput(
      value,
      childScope,
    ),
    skir.PresentationElement_appearanceDefaultsWrapper(:final value) =>
      PortablePresentationNodeRenderer(
        node: value.child,
        scope: childScope.withAppearance(value.appearance),
        fillAvailableSpace: fillAvailableSpace,
      ),
    skir.PresentationElement_namedInputWrapper(:final value) => _renderNamed(
      value,
      childScope,
    ),
    skir.PresentationElement_numericInputWrapper(:final value) =>
      _renderNumericInput(value, childScope),
    skir.PresentationElement_toggleInputWrapper(:final value) =>
      _renderToggleInput(value, childScope),
    skir.PresentationElement_selectInputWrapper(:final value) =>
      _renderSelectInput(value, childScope),
    skir.PresentationElement_searchInputWrapper(:final value) =>
      PortableSearchInput(control: value, scope: childScope),
    skir.PresentationElement_sliderInputWrapper(:final value) =>
      _renderSliderInput(value, childScope),
    skir.PresentationElement_dateTimeInputWrapper(:final value) =>
      _renderDateTimeInput(context, value, childScope),
    skir.PresentationElement_durationInputWrapper(:final value) =>
      _renderDurationInput(value, childScope),
    skir.PresentationElement_colorInputWrapper(:final value) =>
      _renderColorInput(context, value, childScope),
    skir.PresentationElement_bytesInputWrapper(:final value) =>
      _renderBytesInput(value, childScope),
    skir.PresentationElement_enumInputWrapper(:final value) => _renderEnumInput(
      value,
      childScope,
    ),
    skir.PresentationElement_polymorphicInputWrapper(:final value) =>
      _renderPolymorphicInput(context, value, childScope),
    skir.PresentationElement_polymorphicMatchWrapper(:final value) =>
      _renderPolymorphicMatch(value, childScope),
    skir.PresentationElement_listInputWrapper(:final value) => _renderListInput(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_setInputWrapper(:final value) => _renderSetInput(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_mapInputWrapper(:final value) => _renderMapInput(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_recordInputWrapper(:final value) =>
      _renderRecordInput(value, childScope),
    skir.PresentationElement_defaultPresentationWrapper(:final value) =>
      _renderDefaultPresentation(value, childScope),
    skir.PresentationElement_remainingFieldsWrapper(:final value) =>
      _renderRemainingFields(context, value, childScope),
    skir.PresentationElement_invocationWrapper(:final value) =>
      _renderInvocation(value, childScope),
    skir.PresentationElement_nullableInputWrapper(:final value) =>
      _renderNullableInput(value, childScope),
    skir.PresentationElement_linkInputWrapper(:final value) => _renderLinkInput(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_pageGraphWrapper(:final value) => _renderPageGraph(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_pageTimelineWrapper(:final value) =>
      _renderPageTimeline(context, value, childScope),
    skir.PresentationElement_commitControlsWrapper(:final value) =>
      _renderCommitControls(value, childScope),
    skir.PresentationElement_buttonWrapper(:final value) => _renderButton(
      value,
      childScope,
    ),
    skir.PresentationElement_iconButtonWrapper(:final value) =>
      _renderIconButton(value, childScope),
    skir.PresentationElement_menuWrapper(:final value) => _renderMenu(
      value,
      childScope,
    ),
    skir.PresentationElement_tooltipWrapper(:final value) => _renderTooltip(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_richTextWrapper(:final value) => _renderRichText(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_adaptiveLeadingWrapper(:final value) =>
      _renderAdaptiveLeading(value, childScope),
    skir.PresentationElement_alignWrapper(:final value) => _renderAlignment(
      value,
      childScope,
    ),
    skir.PresentationElement_containerWrapper(:final value) => _renderContainer(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_sectionWrapper(:final value) => _renderSection(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_paddingWrapper(:final value) => Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        value.start,
        value.top,
        value.end,
        value.bottom,
      ),
      child: PortablePresentationNodeRenderer(
        node: value.child,
        scope: childScope,
      ),
    ),
    skir.PresentationElement_dividerWrapper(:final value) => _renderDivider(
      context,
      value,
      childScope,
    ),
    skir.PresentationElement_spacerWrapper(:final value) => _renderSpacer(
      value,
      childScope,
    ),
    skir.PresentationElement_anchorWrapper(:final value) => value.render(
      context,
      childScope,
    ),
    skir.PresentationElement_connectionLayerWrapper(:final value) =>
      value.render(context, childScope),
    _ => _diagnostic(
      "Presentation element ${element.kind.name} is not implemented",
    ),
  };

  Widget _renderSlot(
    skir.PresentationSlotElement element,
    PortablePresentationScope childScope,
  ) {
    final builder = childScope.slotBuilders[element.slotId];
    if (builder != null) return builder(childScope);
    final content = childScope.slots[element.slotId];
    return content == null
        ? const SizedBox.shrink()
        : PortablePresentationNodeRenderer(node: content, scope: childScope);
  }
}

typedef PortablePresentationScopeBuilder = PortablePresentationScope Function({
  required PortablePresentationHost host,
  required PortablePresentationDocument document,
  required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
  required PortableOperationResults operations,
  required ValueChanged<String> reportStatus,
});

/// Renders one logical editor through a replaceable presentation adapter.
///
/// Supply a resource key when the parent can rebind this widget. Compatible
/// host refreshes retain controls and completed diagnostic feedback. A new
/// catalog generation starts a new interpretation lifetime.
final class PortablePresentationRenderer extends HookWidget {
  const PortablePresentationRenderer({
    required this.host,
    this.scopeBuilder,
    this.onStatus,
    this.fillAvailableSpace = false,
    super.key,
  });
  final PortablePresentationHost host;
  final PortablePresentationScopeBuilder? scopeBuilder;
  final ValueChanged<String>? onStatus;
  final bool fillAvailableSpace;

  @override
  Widget build(BuildContext context) {
    useListenable(host);
    final document = host.document;
    final generation = document.catalog.snapshot.generation;
    final operations = useMemoized(PortableOperationResults.new, [generation])
      ..onStatus = onStatus;
    useEffect(() => operations.dispose, [operations]);
    useEffect(() {
      operations.retirePending();
      return null;
    }, [host, operations]);
    final Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings;
    try {
      bindings =
          {
            for (final entry in document.bindings.entries)
              entry.key: PortableExpressionBinding(
                value: entry.value.value,
                location: entry.value.location,
                schema: entry.value.schema,
              ),
          }.withPresentationEnvironment(
            PresentationEnvironment.maybeOf(context)?.bindings ?? const {},
          );
    } on StateError catch (error) {
      return _diagnostic(error.message);
    }
    final scope =
        scopeBuilder?.call(
          host: host,
          document: document,
          bindings: bindings,
          operations: operations,
          reportStatus: operations.reportStatus,
        ) ??
        PortablePresentationScope(
          bindings: bindings,
          budget: document.budget,
          enabled: host.enabled,
          readOnly: host.readOnly,
          operations: operations,
          watchSearch: host.capabilities.watchSearch,
          openResource: host.capabilities.openResource,
          reportStatus: operations.reportStatus,
          catalog: document.catalog,
          role: document.role,
          material: document.material,
          activePresentations: document.activePresentations,
          slots: document.slots,
          host: host,
        );
    final root = PortablePresentationNodeRenderer(
      node: document.root,
      scope: scope,
      fillAvailableSpace:
          fillAvailableSpace || document.role == skir.PresentationRole.editor,
    );
    return _PortableDiagnosticBoundary(
      key: ValueKey(generation),
      operations: operations,
      diagnostics: document.diagnostics,
      observations: document.diagnosticObservations,
      child: PortablePresentationChrome(role: document.role, child: root),
    );
  }
}
