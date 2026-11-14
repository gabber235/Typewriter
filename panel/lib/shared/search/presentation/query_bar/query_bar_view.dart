part of "query_bar.dart";

class _QueryBarView extends StatelessWidget {
  const _QueryBarView({required this.bar, required this.controller});

  final QueryBar bar;
  final _QueryBarController controller;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space1,
      children: [
        Actions(
          actions: {
            if (bar.onCancel case final cancel?)
              CancelIntent: CallbackAction<CancelIntent>(
                onInvoke: (_) {
                  cancel();
                  return null;
                },
              ),
          },
          child: AnchoredOverlayPortal(
            visible: controller.popupVisible,
            config: const AnchoredOverlayConfig(
              preferredSide: AnchoredOverlaySide.bottom,
              spacing: 4,
              sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
            ),
            child: _LoadingEdge(
              label: bar.loadingLabel,
              child: EditorTextField(
                inputFieldController: controller.inputFieldController,
                controller: controller.textController,
                style: bar.style,
                textAlign: bar.textAlign,
                autofocus: bar.autofocus,
                decoration: bar.inputDecoration.copyWith(
                  errorText:
                      controller.parseResult.issues.isNotEmpty ||
                          bar.validationIssues.isNotEmpty
                      ? [
                          ...controller.parseResult.issues,
                          ...bar.validationIssues,
                        ].first.message
                      : null,
                  contentPadding:
                      bar.inputDecoration.contentPadding ??
                      EdgeInsets.symmetric(
                        vertical: context.spacing.space3,
                        horizontal: context.spacing.space2,
                      ),
                ),
                maxLines: null,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r"[\n\r]")),
                ],
                textFieldActions: [
                  ...?bar.textFieldActions,
                  ...controller.shortcuts,
                ],
                selectAllOnFocus: bar.selectAllOnFocus,
                enabled: bar.enabled,
                readOnly: bar.readOnly,
                onInputFocus: bar.onInputFocus,
                onDismiss: bar.onDismiss,
                onChanged: controller.onQueryChanged,
                onDone: bar.onDone,
                onEditingComplete: bar.onEditingComplete,
                onSubmitted: controller.onSubmitted,
              ),
            ),
            overlayBuilder: (context, _) => _buildSuggestionPanel(
              context: context,
              suggestions: controller.suggestions,
              warning: controller.completionWarning,
              activeSuggestionIndex: controller.activeSuggestionIndex,
              onTapSuggestion: controller.applySuggestion,
              onHoverIndex: controller.onHoverIndex,
            ),
          ),
        ),
        _QueryBarHelperRow(
          visible: controller.helperVisible,
          badges: controller.helperBadges,
        ),
      ],
    );
    return ManagedActionSet(
      shortcuts: controller.shortcuts,
      child: MotionSize(
        shrink: MotionToken.panelOut,
        alignment: Alignment.topCenter,
        child: content,
      ),
    );
  }
}

class _QueryBarHelperRow extends StatelessWidget {
  const _QueryBarHelperRow({required this.visible, required this.badges});

  final bool visible;
  final _HelperBadgeData badges;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: PanelSwitcher(
        alignment: Alignment.topLeft,
        child: !visible
            ? null
            : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space2,
                ),
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(text: "You can use: "),
                      for (final label in badges.labels) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _buildHelperBadge(
                            context,
                            label,
                            key: ValueKey("query_bar_helper_badge_$label"),
                          ),
                        ),
                        TextSpan(text: ", "),
                      ],
                      if (badges.hiddenCount > 0)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _buildHelperBadge(
                            context,
                            "+${badges.hiddenCount}",
                            key: const ValueKey(
                              "query_bar_helper_badge_overflow",
                            ),
                          ),
                        ),
                      TextSpan(text: "to filter results."),
                      if (context.isTablet || context.isDesktop) ...[
                        TextSpan(text: " Press "),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: ShortcutDisplay(
                            shortcut: SingleActivator(LogicalKeyboardKey.enter),
                          ),
                        ),
                        TextSpan(text: " to select first result."),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Lays a [WorkingLine] along the bottom edge of [child] while [label] is
/// set. The line stays inside the straight part of the edge, so it never meets
/// the rounded corners or the focus ring around them.
class _LoadingEdge extends StatelessWidget {
  const _LoadingEdge({required this.label, required this.child});

  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    if (label == null) return child;
    final corner = context.shapes.largeBorderRadius.bottomLeft.x;
    return Stack(
      children: [
        child,
        Positioned(
          left: corner,
          right: corner,
          bottom: 0,
          child: WorkingLine(label: label),
        ),
      ],
    );
  }
}
