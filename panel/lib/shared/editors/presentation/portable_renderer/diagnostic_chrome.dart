part of "../portable_presentation_renderer.dart";

@freezed
abstract class PortableControlValidationIdentity
    with _$PortableControlValidationIdentity {
  const factory PortableControlValidationIdentity({
    required Object owner,
    required PortableDiagnosticTarget target,
  }) = _PortableControlValidationIdentity;
}

class PortableDiagnosticFrame extends HookWidget {
  const PortableDiagnosticFrame({
    required this.target,
    required this.value,
    required this.child,
    this.label,
    this.description,
    this.scope,
    this.appearance,
    super.key,
  });
  final PortablePresentationScope? scope;
  final skir.InputAppearance? appearance;
  final String? label;
  final String? description;
  final PortableDiagnosticTarget target;
  final skir.DataValue? value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tree = PortableDiagnosticScope.of(context).tree;
    final identity = PortableControlValidationIdentity(
      owner: tree,
      target: target,
    );
    final currentIdentity = useRef(identity)..value = identity;
    final parseMessage = useState<String?>(null);
    useEffect(() {
      parseMessage.value = null;
      return null;
    }, [identity, value]);
    void reportParseMessage(String? message) {
      if (context.mounted && currentIdentity.value == identity) {
        parseMessage.value = message;
      }
    }

    final local = parseMessage.value == null
        ? const <PortablePresentationDiagnostic>[]
        : [
            PortablePresentationDiagnostic(
              code: "invalid_input",
              message: parseMessage.value!,
              severity: skir.DiagnosticSeverity.error,
              targets: [target],
            ),
          ];
    return PortableDiagnosticAnchor(
      node: PortableDiagnosticNode(
        kind: PortableDiagnosticNodeKind.control,
        observations: [
          PortableDiagnosticObservation(target: target, value: value),
        ],
        diagnostics: local,
      ),
      builder: (context, summary, owner) {
        final direct = {...summary.direct, ...local}.toList();
        final effective = PortableDiagnosticSummary(
          direct: direct,
          descendants: summary.descendants,
        );
        final severity = effective.highestSeverity;
        final color = severity?.color(context);
        final colors = context.theme.colorScheme;
        final fill = severity == skir.DiagnosticSeverity.error
            ? colors.errorContainer
            : color?.withValues(alpha: 0.18);
        final hasLabel =
            (label != null && label!.isNotEmpty) ||
            (description != null && description!.isNotEmpty);
        final nativeInteraction = PresentationInteractionScope.of(context);
        _PortableControlStyle? style;
        try {
          style = scope == null
              ? null
              : _controlStyle(
                  context,
                  scope!,
                  appearance,
                  environment: PresentationValueEnvironment.of(context)
                      .copyWith(
                        interaction: nativeInteraction.copyWith(
                          invalid: severity == skir.DiagnosticSeverity.error,
                        ),
                      ),
                );
        } on PresentationColorFailure catch (failure) {
          return _diagnostic(failure.message);
        }
        final authoredLabelColor =
            appearance?.labelStyle?.color != null ||
            (scope?.appearanceLayers.any(
                  (layer) => layer.appearance.labelStyle?.color != null,
                ) ??
                false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            LabeledMessage(
              label: label,
              message: description,
              labelStyle:
                  style?.labelStyle.copyWith(
                    color: authoredLabelColor
                        ? style.labelStyle.color
                        : color ?? style.labelStyle.color,
                  ) ??
                  context.theme.textTheme.labelLarge?.copyWith(color: color),
              messageStyle: style?.descriptionStyle,
            ),
            if (hasLabel) const SizedBox(height: 6),
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: fill ?? context.colors.surface.withValues(alpha: 0),
                borderRadius: context.shapes.mediumBorderRadius,
              ),
              padding: severity == null
                  ? EdgeInsets.zero
                  : EdgeInsets.all(context.spacing.space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PortableControlDiagnostics(
                    identity: identity,
                    invalid: severity == skir.DiagnosticSeverity.error,
                    onValidationChanged: reportParseMessage,
                    child: child,
                  ),
                  PortableDiagnosticMessages(diagnostics: direct),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class PortableControlDiagnostics extends InheritedWidget {
  const PortableControlDiagnostics({
    required this.identity,
    required this.onValidationChanged,
    required super.child,
    this.invalid = false,
    super.key,
  });
  final bool invalid;
  final PortableControlValidationIdentity identity;
  final ValueChanged<String?> onValidationChanged;
  static PortableControlDiagnostics of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortableControlDiagnostics>()!;
  @override
  bool updateShouldNotify(PortableControlDiagnostics old) =>
      invalid != old.invalid ||
      identity != old.identity ||
      onValidationChanged != old.onValidationChanged;
}

class PortableDiagnosticMessages extends StatelessWidget {
  const PortableDiagnosticMessages({required this.diagnostics, super.key});
  final List<PortablePresentationDiagnostic> diagnostics;
  @override
  Widget build(BuildContext context) {
    return ElasticMessageSwitcher(
      child: diagnostics.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(PortableDiagnosticSummary(direct: diagnostics)),
              padding: EdgeInsets.only(
                top: context.spacing.space1,
                left: context.spacing.space2,
                right: context.spacing.space2,
              ),
              child: Semantics(
                liveRegion: true,
                label: diagnostics.map((item) => item.message).join("\n"),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final diagnostic in diagnostics)
                        Text(
                          diagnostic.message,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            color: Color.alphaBlend(
                              diagnostic.severity
                                  .color(context)
                                  .withValues(
                                    alpha: context.isDarkMode ? 0.4 : 0.9,
                                  ),
                              Surface.colorOf(context).on(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class PortableDiagnosticHeaderMarker extends StatelessWidget {
  const PortableDiagnosticHeaderMarker({required this.summary, super.key});
  final PortableDiagnosticSummary summary;
  @override
  Widget build(BuildContext context) {
    final count = {...summary.direct, ...summary.descendants}.length;
    final label = count == 1
        ? "1 field diagnostic"
        : "$count field diagnostics";
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Icon(
          switch (summary.highestSeverity?.kind) {
            skir.DiagnosticSeverity_kind.informationConst => Icons.info_outline,
            skir.DiagnosticSeverity_kind.warningConst =>
              Icons.warning_amber_rounded,
            _ => Icons.error_outline,
          },
          size: 18,
          color: summary.highestSeverity?.color(context),
        ),
      ),
    );
  }
}

/// Keeps the presentation subtree mounted as general feedback changes.
/// Compact cards expose details through keyboard focus without consuming card taps.
class PortablePresentationChrome extends HookWidget {
  const PortablePresentationChrome({
    required this.role,
    required this.child,
    super.key,
  });
  final skir.PresentationRole? role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tooltip = useMemoized(GlobalKey<TooltipState>.new);
    final placement = PortableDiagnosticScope.of(context).placement;
    final expanded =
        role == skir.PresentationRole.workspace ||
        role == skir.PresentationRole.inspector;
    final diagnostics = expanded
        ? placement.general
        : {...placement.general, ...placement.unplaced}.toList();
    final severity = PortableDiagnosticSummary(direct: diagnostics)
        .highestSeverity;
    final label = switch (severity?.kind) {
      skir.DiagnosticSeverity_kind.informationConst =>
        "Presentation information",
      skir.DiagnosticSeverity_kind.warningConst => "Presentation warning",
      _ => "Presentation error",
    };
    final icon = switch (severity?.kind) {
      skir.DiagnosticSeverity_kind.informationConst =>
        Icons.info_outline_rounded,
      skir.DiagnosticSeverity_kind.warningConst => Icons.warning_amber_rounded,
      _ => Icons.error_outline_rounded,
    };
    final focus = useFocusNode(debugLabel: label);
    useFocusedChange(focus, ({required hasFocus}) {
      if (hasFocus && diagnostics.isNotEmpty) {
        tooltip.currentState?.ensureTooltipVisible();
      } else {
        Tooltip.dismissAllToolTips();
      }
    }, [focus, diagnostics]);
    if (expanded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fill = constraints.hasBoundedHeight;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            children: [
              PortableDiagnosticMessages(diagnostics: diagnostics),
              if (fill) Expanded(child: child) else child,
            ],
          );
        },
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        PositionedDirectional(
          top: 0,
          end: 0,
          child: ExcludeFocus(
            excluding: diagnostics.isEmpty,
            child: Visibility(
              visible: diagnostics.isNotEmpty,
              maintainState: true,
              child: IgnorePointer(
                child: Tooltip(
                  key: tooltip,
                  message: diagnostics.map((item) => item.message).join("\n"),
                  triggerMode: TooltipTriggerMode.manual,
                  excludeFromSemantics: true,
                  child: Semantics(
                    label: label,
                    child: IconButton(
                      focusNode: focus,
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(20),
                        maximumSize: const Size.square(20),
                        fixedSize: const Size.square(20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.standard,
                        padding: const EdgeInsets.all(2),
                      ),
                      onPressed: () =>
                          tooltip.currentState?.ensureTooltipVisible(),
                      icon: Icon(
                        icon,
                        size: 16,
                        color: severity?.color(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
