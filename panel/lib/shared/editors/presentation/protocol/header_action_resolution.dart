part of "header_renderer.dart";

@freezed
abstract class _ResolvedHeaderAction with _$ResolvedHeaderAction {
  const factory _ResolvedHeaderAction({
    required HeaderActionId id,
    required IconValue icon,
    required String label,
    required String tooltip,
    required HeaderActionActivation activation,
    required int priority,
    required int declarationOrder,
    required bool visible,
    required bool enabled,
    required HeaderActionPlacement placement,
    required HeaderActionTone tone,
    required _ResolvedConfirmation? confirmation,
  }) = _ResolvedHeaderActionValue;

  const _ResolvedHeaderAction._();

  bool get immediate => activation is InvokeHeaderAction;

  ActionShortcut _shortcut(
    BuildContext context,
    List<ShortcutActivator> activators,
    PresentationRenderScope scope,
  ) => ActionShortcut(
    id: id.qualified,
    label: label,
    description: tooltip,
    activators: activators,
    priority: priority,
    icon: Icones.value(icon),
    onInvoke: enabled && immediate ? (ref) => _invoke(context, scope) : null,
  );

  Widget _button(BuildContext context, PresentationRenderScope scope) =>
      IconButton(
        tooltip: tooltip,
        onPressed: enabled ? () => _invoke(context, scope) : null,
        color: tone == HeaderActionTone.destructive
            ? Theme.of(context).colorScheme.error
            : null,
        icon: Icones.value(icon),
      );

  Future<void> _invoke(
    BuildContext context,
    PresentationRenderScope? scope,
  ) async {
    final invocation = activation;
    if (!enabled || invocation is! InvokeHeaderAction || scope == null) return;
    if (confirmation case final value?) {
      final colorScheme = Theme.of(context).colorScheme;
      await showConfirmationDialogue(
        context: context,
        title: value.title,
        content: value.message,
        confirmText: value.confirmationLabel,
        confirmColor: tone == HeaderActionTone.destructive
            ? colorScheme.error
            : colorScheme.primary,
        onConfirmColor: tone == HeaderActionTone.destructive
            ? colorScheme.onError
            : colorScheme.onPrimary,
        onConfirm: () => scope.invoke(invocation.action),
      );
      return;
    }
    scope.invoke(invocation.action);
  }
}

@freezed
abstract class _ResolvedConfirmation with _$ResolvedConfirmation {
  const factory _ResolvedConfirmation({
    required String title,
    required String message,
    required String confirmationLabel,
  }) = _ResolvedConfirmationValue;
}

extension on EditorHeaderAction {
  _ResolvedHeaderAction _resolve(
    PresentationRenderScope scope,
    int declarationOrder,
  ) {
    final diagnostics = <TypeDiagnostic>[];
    final resolvedIcon = icon._icon(scope, diagnostics);
    final resolvedLabel = label._string(scope, diagnostics);
    final resolvedTooltip =
        tooltip?._string(scope, diagnostics) ?? resolvedLabel;
    final resolvedPriority = priority?._integer(scope, diagnostics) ?? 0;
    final resolvedVisible = visibleIf?._boolean(scope, diagnostics) ?? true;
    final resolvedEnabled = enabledIf?._boolean(scope, diagnostics) ?? true;
    final allowedByScope =
        scope.enabled && !(scope.readOnly && activation._isLocal);
    final resolvedConfirmation = confirmation?._resolve(scope, diagnostics);
    return _ResolvedHeaderAction(
      id: id,
      icon: resolvedIcon ?? const IconValue.iconify("mdi:alert-circle-outline"),
      label: diagnostics.isEmpty ? resolvedLabel : "Invalid action",
      tooltip: diagnostics.isEmpty
          ? resolvedTooltip
          : diagnostics.map((item) => item.message).join("\n"),
      activation: activation,
      priority: resolvedPriority,
      declarationOrder: declarationOrder,
      visible: resolvedVisible,
      enabled: diagnostics.isEmpty && resolvedEnabled && allowedByScope,
      placement: placement,
      tone: tone,
      confirmation: resolvedConfirmation,
    );
  }
}

extension on HeaderActionActivation {
  bool get _isLocal => switch (this) {
    InvokeHeaderAction(action: LocalEditorAction()) => true,
    _ => false,
  };
}

extension on HeaderActionConfirmation {
  _ResolvedConfirmation _resolve(
    PresentationRenderScope scope,
    List<TypeDiagnostic> diagnostics,
  ) => _ResolvedConfirmation(
    title: title._string(scope, diagnostics),
    message: message._string(scope, diagnostics),
    confirmationLabel: confirmationLabel._string(scope, diagnostics),
  );
}

extension on TypedExpression {
  DataValue? _value(
    PresentationRenderScope scope,
    List<TypeDiagnostic> diagnostics,
  ) {
    final result = scope.evaluate(this);
    diagnostics.addAll(result.diagnostics);
    return result.valueOrNull;
  }

  String _string(
    PresentationRenderScope scope,
    List<TypeDiagnostic> diagnostics,
  ) {
    final value = _value(scope, diagnostics);
    if (value case StringValue(:final value)) return value;
    diagnostics.add(
      _invalidHeaderValue("Header text must evaluate to a string"),
    );
    return "";
  }

  bool _boolean(
    PresentationRenderScope scope,
    List<TypeDiagnostic> diagnostics,
  ) {
    final value = _value(scope, diagnostics);
    if (value case BooleanValue(:final value)) return value;
    diagnostics.add(
      _invalidHeaderValue("Header condition must evaluate to boolean"),
    );
    return false;
  }

  int _integer(
    PresentationRenderScope scope,
    List<TypeDiagnostic> diagnostics,
  ) {
    final value = _value(scope, diagnostics);
    if (value case IntegerValue(:final value)) return value.toInt();
    diagnostics.add(
      _invalidHeaderValue("Header priority must evaluate to an integer"),
    );
    return 0;
  }

  IconValue? _icon(
    PresentationRenderScope scope,
    List<TypeDiagnostic> diagnostics,
  ) {
    final value = _value(scope, diagnostics);
    if (value case PolymorphicValue(
      :final concreteType,
      value: StringValue(:final value),
    )) {
      if (concreteType == standardTypeRefs.iconifyIcon) {
        return IconValue.iconify(value);
      }
      if (concreteType == standardTypeRefs.svgIcon) return IconValue.svg(value);
    }
    diagnostics.add(_invalidHeaderValue("Header icon must evaluate to Icon"));
    return null;
  }
}

TypeDiagnostic _invalidHeaderValue(String message) =>
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message);
