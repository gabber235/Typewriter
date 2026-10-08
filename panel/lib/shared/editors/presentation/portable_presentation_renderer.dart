import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_renderer/actions.dart";
part "portable_renderer/collection_inputs.dart";
part "portable_renderer/collections.dart";
part "portable_renderer/content.dart";
part "portable_renderer/control_frame.dart";
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
    final enabled = _boolean(scope, node.properties.enabledIf, fallback: true);
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
    final rendered = _renderElement(context, element, childScope);
    var child = node.header == null
        ? rendered
        : _AuthoredPresentationHeader(
            header: node.header!,
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
      value,
      childScope,
    ),
    skir.PresentationElement_iconWrapper(:final value) => _renderIcon(
      value,
      childScope,
    ),
    skir.PresentationElement_imageWrapper(:final value) => _renderImage(
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
    skir.PresentationElement_commitControlsWrapper() => _renderCommitControls(
      childScope,
    ),
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
      value,
      childScope,
    ),
    skir.PresentationElement_richTextWrapper(:final value) => _renderRichText(
      value,
      childScope,
    ),
    skir.PresentationElement_adaptiveLeadingWrapper(:final value) =>
      _renderAdaptiveLeading(value, childScope),
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
    skir.PresentationElement.divider => const Divider(),
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
  required void Function(skir.BindingRef, skir.DataValue) setBinding,
  required ValueChanged<String> reportStatus,
});

final class PortablePresentationRenderer extends StatefulWidget {
  const PortablePresentationRenderer({
    required this.host,
    this.scopeBuilder,
    this.onStatus,
    this.compactDiagnostics = const [],
    super.key,
  });

  final PortablePresentationHost host;
  final PortablePresentationScopeBuilder? scopeBuilder;
  final ValueChanged<String>? onStatus;
  final List<skir.DiagnosticTemplate> compactDiagnostics;

  @override
  State<PortablePresentationRenderer> createState() =>
      _PortablePresentationRendererState();
}

final class _PortablePresentationRendererState
    extends State<PortablePresentationRenderer> {
  String? _status;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.host,
    builder: (context, _) {
      final document = widget.host.document;
      final bindings = {
        for (final entry in document.bindings.entries)
          entry.key: PortableExpressionBinding(
            value: entry.value.value,
            location: entry.value.location,
          ),
      };
      final scope =
          widget.scopeBuilder?.call(
            host: widget.host,
            document: document,
            bindings: bindings,
            setBinding: _setBinding,
            reportStatus: _reportStatus,
          ) ??
          _defaultScope(document, bindings);
      final root = PortablePresentationNodeRenderer(
        node: document.root,
        scope: scope,
        fillAvailableSpace: document.role == skir.PresentationRole.editor,
      );
      if (document.role == skir.PresentationRole.editor) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_status case final status?)
              Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
            Expanded(child: root),
          ],
        );
      }
      if (document.role != skir.PresentationRole.inspector) {
        final diagnostics = [
          ...widget.compactDiagnostics,
          if (_status case final status?)
            skir.DiagnosticTemplate(
              code: "presentation_status",
              message: status,
              severity: skir.DiagnosticSeverity.error,
              targets: const [],
            ),
        ];
        if (diagnostics.isEmpty) return root;
        return _CompactPresentationNotice(
          diagnostics: diagnostics,
          child: root,
        );
      }
      if (_status == null) return root;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status case final status?)
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.danger,
                ),
              ),
            ),
          root,
        ],
      );
    },
  );

  PortablePresentationScope _defaultScope(
    PortablePresentationDocument document,
    Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
  ) {
    final capabilities = widget.host.capabilities;
    return PortablePresentationScope(
      bindings: bindings,
      budget: document.budget,
      setBinding: _setBinding,
      enabled: widget.host.enabled,
      readOnly: widget.host.readOnly,
      invokeCommand: capabilities.invokeCommand,
      watchSearch: capabilities.watchSearch,
      reload: capabilities.reload,
      commit: capabilities.commit,
      openResource: capabilities.openResource,
      prepareCreation: capabilities.prepareCreation,
      reportStatus: _reportStatus,
      catalog: document.catalog,
      role: document.role,
      material: document.material,
      activePresentations: document.activePresentations,
      slots: document.slots,
      host: widget.host,
    );
  }

  void _setBinding(skir.BindingRef reference, skir.DataValue value) {
    unawaited(_write(reference, value));
  }

  Future<void> _write(skir.BindingRef reference, skir.DataValue value) async {
    final result = await widget.host.write(reference, value);
    if (!mounted) return;
    switch (result) {
      case PortablePresentationWriteApplied():
        if (_status != null) setState(() => _status = null);
      case PortablePresentationWriteRejected(:final message):
        _reportStatus(message);
    }
  }

  void _reportStatus(String message) {
    widget.onStatus?.call(message);
    if (!mounted || widget.onStatus != null) return;
    setState(() => _status = message);
  }
}

final class _CompactPresentationNotice extends StatefulWidget {
  const _CompactPresentationNotice({
    required this.diagnostics,
    required this.child,
  });

  final List<skir.DiagnosticTemplate> diagnostics;
  final Widget child;

  @override
  State<_CompactPresentationNotice> createState() =>
      _CompactPresentationNoticeState();
}

final class _CompactPresentationNoticeState
    extends State<_CompactPresentationNotice> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final message = widget.diagnostics
        .map((diagnostic) => diagnostic.message)
        .join("\n");
    final severity = _strongestSeverity(widget.diagnostics);
    final label = switch (severity.kind) {
      skir.DiagnosticSeverity_kind.informationConst =>
        "Presentation information",
      skir.DiagnosticSeverity_kind.warningConst => "Presentation warning",
      skir.DiagnosticSeverity_kind.errorConst => "Presentation error",
      skir.DiagnosticSeverity_kind.unknown => "Presentation problem",
    };
    final color = switch (severity.kind) {
      skir.DiagnosticSeverity_kind.informationConst => context.colors.info,
      skir.DiagnosticSeverity_kind.warningConst => context.colors.warning,
      skir.DiagnosticSeverity_kind.errorConst ||
      skir.DiagnosticSeverity_kind.unknown => context.colors.danger,
    };
    final icon = switch (severity.kind) {
      skir.DiagnosticSeverity_kind.informationConst =>
        Icons.info_outline_rounded,
      skir.DiagnosticSeverity_kind.warningConst => Icons.warning_amber_rounded,
      skir.DiagnosticSeverity_kind.errorConst ||
      skir.DiagnosticSeverity_kind.unknown => Icons.error_outline_rounded,
    };
    return Tooltip(
      key: _tooltipKey,
      message: message,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IgnorePointer(
              child: Focus(
                debugLabel: label,
                onFocusChange: (focused) {
                  if (!focused) {
                    Tooltip.dismissAllToolTips();
                    return;
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _tooltipKey.currentState?.ensureTooltipVisible();
                    }
                  });
                },
                child: Semantics(
                  label: label,
                  tooltip: message,
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(icon, size: 14, color: color),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

skir.DiagnosticSeverity _strongestSeverity(
  Iterable<skir.DiagnosticTemplate> diagnostics,
) => diagnostics.map((diagnostic) => diagnostic.severity).reduce((
  current,
  next,
) {
  final currentRank = _diagnosticSeverityRank(current);
  final nextRank = _diagnosticSeverityRank(next);
  return nextRank > currentRank ? next : current;
});

int _diagnosticSeverityRank(skir.DiagnosticSeverity severity) =>
    switch (severity.kind) {
      skir.DiagnosticSeverity_kind.informationConst => 0,
      skir.DiagnosticSeverity_kind.warningConst => 1,
      skir.DiagnosticSeverity_kind.errorConst ||
      skir.DiagnosticSeverity_kind.unknown => 2,
    };
