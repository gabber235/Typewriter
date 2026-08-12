part of "presentation_substitution.dart";

extension on PresentationHeader {
  PresentationHeader _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => PresentationHeader(
    binding: binding,
    title: title._substituteTypes(substitutions),
    description: description._substituteTypes(substitutions),
    initiallyExpanded: initiallyExpanded,
    items: [for (final item in items) item._substituteTypes(substitutions)],
  );
}

extension on HeaderItem {
  HeaderItem _substituteTypes(Map<String, TypeExpression> substitutions) =>
      switch (this) {
        HeaderButtonItem(
          :final id,
          :final icon,
          :final label,
          :final action,
          :final tooltip,
          :final priority,
          :final visibleIf,
          :final enabledIf,
          :final placement,
          :final tone,
          :final confirmation,
        ) =>
          HeaderButtonItem(
            id: id,
            icon: icon.substituteTypes(substitutions),
            label: label.substituteTypes(substitutions),
            action: action.substituteTypes(substitutions),
            tooltip: tooltip._substituteTypes(substitutions),
            priority: priority._substituteTypes(substitutions),
            visibleIf: visibleIf._substituteTypes(substitutions),
            enabledIf: enabledIf._substituteTypes(substitutions),
            placement: placement,
            tone: tone,
            confirmation: confirmation?._substituteTypes(substitutions),
          ),
        HeaderBooleanToggleItem(
          :final id,
          :final label,
          :final checked,
          :final action,
          :final tooltip,
          :final priority,
          :final visibleIf,
          :final enabledIf,
          :final placement,
          :final confirmation,
        ) =>
          HeaderBooleanToggleItem(
            id: id,
            label: label.substituteTypes(substitutions),
            checked: checked.substituteTypes(substitutions),
            action: action.substituteTypes(substitutions),
            tooltip: tooltip._substituteTypes(substitutions),
            priority: priority._substituteTypes(substitutions),
            visibleIf: visibleIf._substituteTypes(substitutions),
            enabledIf: enabledIf._substituteTypes(substitutions),
            placement: placement,
            confirmation: confirmation?._substituteTypes(substitutions),
          ),
        HeaderReorderHandleItem(
          :final id,
          :final label,
          :final source,
          :final tooltip,
          :final visibleIf,
          :final enabledIf,
        ) =>
          HeaderReorderHandleItem(
            id: id,
            label: label.substituteTypes(substitutions),
            source: source,
            tooltip: tooltip._substituteTypes(substitutions),
            visibleIf: visibleIf._substituteTypes(substitutions),
            enabledIf: enabledIf._substituteTypes(substitutions),
          ),
      };
}

extension on HeaderActionConfirmation {
  HeaderActionConfirmation _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => HeaderActionConfirmation(
    title: title.substituteTypes(substitutions),
    message: message.substituteTypes(substitutions),
    confirmationLabel: confirmationLabel.substituteTypes(substitutions),
  );
}
