part of "presentation_substitution.dart";

extension on PresentationHeader {
  PresentationHeader _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => PresentationHeader(
    binding: binding,
    title: title._substituteTypes(substitutions),
    description: description._substituteTypes(substitutions),
    initiallyExpanded: initiallyExpanded,
    actions: [
      for (final action in actions)
        EditorHeaderAction(
          id: action.id,
          icon: action.icon.substituteTypes(substitutions),
          label: action.label.substituteTypes(substitutions),
          activation: switch (action.activation) {
            InvokeHeaderAction(:final action) => InvokeHeaderAction(
              action.substituteTypes(substitutions),
            ),
            ReorderListItemHeaderAction() => action.activation,
          },
          tooltip: action.tooltip._substituteTypes(substitutions),
          priority: action.priority._substituteTypes(substitutions),
          visibleIf: action.visibleIf._substituteTypes(substitutions),
          enabledIf: action.enabledIf._substituteTypes(substitutions),
          placement: action.placement,
          tone: action.tone,
          confirmation: action.confirmation?._substituteTypes(substitutions),
        ),
    ],
  );
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
