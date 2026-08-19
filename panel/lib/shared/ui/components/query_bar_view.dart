part of "query_bar.dart";

class _QueryBarView extends StatelessWidget {
  const _QueryBarView({required this.bar, required this.controller});

  final QueryBar bar;
  final _QueryBarController controller;

  @override
  Widget build(BuildContext context) {
    return ManagedActionSet(
      shortcuts: controller.shortcuts,
      child: AnimatedSize(
        duration: 300.ms,
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            AnchoredOverlayPortal(
              visible: controller.popupVisible,
              config: const AnchoredOverlayConfig(
                preferredSide: AnchoredOverlaySide.bottom,
                spacing: 4,
                sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
              ),
              child: EditorTextField(
                inputFieldController: controller.inputFieldController,
                controller: controller.textController,
                autofocus: bar.autofocus,
                decoration: bar.inputDecoration.copyWith(
                  errorText: controller.parseResult.issues.isNotEmpty
                      ? controller.parseResult.issues.first.message
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
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
                onCancel: bar.onCancel,
                onChanged: controller.onQueryChanged,
                onDone: bar.onDone,
                onEditingComplete: bar.onEditingComplete,
                onSubmitted: controller.onSubmitted,
              ),
              overlayBuilder: (context, _) => _buildSuggestionPanel(
                context: context,
                suggestions: controller.suggestions,
                activeSuggestionIndex: controller.activeSuggestionIndex,
                onTapSuggestion: controller.applySuggestion,
                onHoverIndex: controller.onHoverIndex,
              ),
            ),
            _QueryBarHelperRow(
              visible: controller.helperVisible,
              badges: controller.helperBadges,
            ),
          ],
        ),
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
      child: AnimatedSwitcher(
        duration: 420.ms,
        reverseDuration: 180.ms,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        transitionBuilder: (child, animation) =>
            ElasticMessageTransition(animation: animation, child: child),
        child: !visible
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
