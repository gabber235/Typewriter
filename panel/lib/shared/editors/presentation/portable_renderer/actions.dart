part of "../portable_presentation_renderer.dart";

extension _PortableScopeActions on PortablePresentationScope {
  Future<void> executeAction(
    skir.EditorAction editorAction, {
    VoidCallback? onApplied,
  }) async {
    final target = host;
    if (!canExecuteActionFor(editorAction) || target == null) return;
    final context = invocation;
    final source = sourceAction(editorAction);
    await operations.run(
      key: PortableOperationKey.execute(source),
      onApplied: onApplied,
      operation: () async {
        if (editorAction
            case skir.EditorAction_localWrapper(
              value: skir.LocalEditorAction_setValueWrapper(:final value),
            )
            when projectedWriters.containsKey(value.target.bindingId)) {
          final evaluated = evaluate(value.value);
          if (evaluated case PortableExpressionAvailable(
            value: final replacement,
          )) {
            return apply(value.target, replacement, reads: evaluated.reads);
          }
          return PortablePresentationWriteRejected([
            PortablePresentationDiagnostic(
              code: "action_value_unavailable",
              message: switch (evaluated) {
                PortableExpressionFailed(:final message) => message,
                _ => "The action value is unavailable",
              },
              severity: skir.DiagnosticSeverity.error,
              targets: [diagnosticTarget(value.target)],
            ),
          ]);
        }
        return target.execute(editorAction, context: context);
      },
    );
  }

  void moveListItem(
    skir.BindingRef target,
    skir.ItemId item,
    skir.ItemId? after,
  ) => unawaited(
    executeAction(
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createMoveListItem(
          target: target,
          item: item,
          after: after,
        ),
      ),
    ),
  );

  Future<void> addCollectionItem(skir.BindingRef reference) async {
    final target = host;
    if (!canExecuteAction || target is! PortableCollectionMutationHost) return;
    final address = diagnosticTarget(reference);
    final context = invocation;
    await operations.run(
      key: PortableOperationKey.addItem(address),
      input: PortableDiagnosticObservation(
        target: address,
        value: read(reference),
      ),
      operation: () => (target! as PortableCollectionMutationHost)
          .addCollectionItem(reference, context: context),
    );
  }

  void addMapRow(skir.BindingRef reference) {
    final target = host;
    if (!canExecuteAction || target is! PortableCollectionMutationHost) return;
    final address = diagnosticTarget(reference);
    final context = invocation;
    unawaited(
      operations.run(
        key: PortableOperationKey.addMapRow(address),
        input: PortableDiagnosticObservation(
          target: address,
          value: read(reference),
        ),
        operation: () => (target! as PortableCollectionMutationHost).addMapRow(
          reference,
          context: context,
        ),
      ),
    );
  }
}

extension _PortableActionRendering on PortablePresentationNodeRenderer {
  Widget _renderCommitControls(
    skir.CommitControlsElement element,
    PortablePresentationScope childScope,
  ) {
    final reference = childScope.sourceReference(element.binding);
    if (reference == null || !childScope.enabled || childScope.readOnly) {
      return const SizedBox.shrink();
    }
    final control = childScope.host?.commitControl(
      reference,
      context: childScope.invocation,
    );
    return control == null
        ? const SizedBox.shrink()
        : ApplyControls(control: control);
  }

  Widget _renderButton(
    skir.ButtonElement button,
    PortablePresentationScope childScope,
  ) => _actionAppearance(childScope, button.appearance, (
    context,
    states,
    style,
    resolved,
  ) {
    final label = _actionText(childScope, button.label)!;
    final icon = button.icon == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(color: resolved.iconColor),
            child: PortablePresentationNodeRenderer(
              node: button.icon!,
              scope: childScope,
            ),
          );
    final content = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(width: context.spacing.space2),
              Text(label),
            ],
          );
    return _nativeActionButton(
      variant: button.appearance?.variant ?? skir.ButtonVariant.filled,
      states: states,
      style: style,
      onPressed: childScope.canExecuteActionFor(button.action)
          ? () => unawaited(childScope.executeAction(button.action))
          : null,
      child: content,
    );
  });

  Widget _renderIconButton(
    skir.IconButtonElement button,
    PortablePresentationScope childScope,
  ) => _actionAppearance(childScope, button.appearance, (
    context,
    states,
    style,
    resolved,
  ) {
    final icon = _actionText(childScope, button.icon)!;
    final label = _actionText(childScope, button.semanticLabel)!;
    final child = Icones(
      icon,
      size: resolved.iconSize,
      color: resolved.iconColor,
    );
    final callback = childScope.canExecuteActionFor(button.action)
        ? () => unawaited(childScope.executeAction(button.action))
        : null;
    return switch (button.appearance?.variant) {
      final variant when variant == skir.ButtonVariant.filled =>
        IconButton.filled(
          statesController: states,
          style: style,
          tooltip: label,
          onPressed: callback,
          icon: child,
        ),
      final variant when variant == skir.ButtonVariant.outlined =>
        IconButton.outlined(
          statesController: states,
          style: style,
          tooltip: label,
          onPressed: callback,
          icon: child,
        ),
      _ => IconButton(
        statesController: states,
        style: style,
        tooltip: label,
        onPressed: callback,
        icon: child,
      ),
    };
  });

  Widget _renderMenu(
    skir.MenuElement menu,
    PortablePresentationScope childScope,
  ) => _actionAppearance(childScope, menu.appearance, (
    context,
    states,
    style,
    resolved,
  ) {
    if (menu.items.where((item) => !item.separator).isEmpty) {
      return _diagnostic("The menu has no available actions");
    }
    final label = _actionText(childScope, menu.label) ?? "Open menu";
    final popup = menu.popup;
    final constraints = _popupConstraints(childScope, popup);
    final shape = _popupShape(context, childScope, popup);
    return MenuAnchor(
      style: MenuStyle(
        minimumSize: constraints == null
            ? null
            : WidgetStatePropertyAll(
                Size(constraints.minWidth, constraints.minHeight),
              ),
        maximumSize: constraints == null
            ? null
            : WidgetStatePropertyAll(
                Size(constraints.maxWidth, constraints.maxHeight),
              ),
        padding: popup?.padding == null
            ? null
            : WidgetStatePropertyAll(_presentationInsets(popup!.padding)),
        backgroundColor: popup?.fill == null
            ? null
            : WidgetStatePropertyAll(_color(context, childScope, popup!.fill)),
        shape: shape == null ? null : WidgetStatePropertyAll(shape),
      ),
      menuChildren: [
        for (final item in menu.items)
          if (item.separator)
            const Divider()
          else
            item.renderConfigured(childScope),
      ],
      builder: (context, controller, child) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        final variant = menu.appearance?.variant;
        if (variant == null) {
          return IconButton(
            statesController: states,
            style: style,
            tooltip: label,
            onPressed: childScope.canExecuteAction ? toggle : null,
            icon: Icones(
              "material-symbols:more-vert",
              color: resolved.iconColor,
            ),
          );
        }
        return _nativeActionButton(
          variant: variant,
          states: states,
          style: style,
          onPressed: childScope.canExecuteAction ? toggle : null,
          child: Text(label),
        );
      },
    );
  });
}

String? _actionText(
  PortablePresentationScope scope,
  skir.ExpressionNode? node,
) => node == null
    ? null
    : switch (_string(scope, node)) {
        _ResolvedValue(:final value) => value,
        _ResolvedFailure(:final message) => throw PresentationColorFailure(
          message,
        ),
      };

Widget _nativeActionButton({
  required skir.ButtonVariant variant,
  required WidgetStatesController states,
  required ButtonStyle style,
  required VoidCallback? onPressed,
  required Widget child,
}) => switch (variant) {
  final value when value == skir.ButtonVariant.outlined => OutlinedButton(
    statesController: states,
    style: style,
    onPressed: onPressed,
    child: child,
  ),
  final value when value == skir.ButtonVariant.text => TextButton(
    statesController: states,
    style: style,
    onPressed: onPressed,
    child: child,
  ),
  _ => FilledButton(
    statesController: states,
    style: style,
    onPressed: onPressed,
    child: child,
  ),
};

Widget _actionAppearance(
  PortablePresentationScope scope,
  skir.ActionAppearance? appearance,
  Widget Function(
    BuildContext,
    WidgetStatesController,
    ButtonStyle,
    _PortableControlStyle,
  )
  builder, {
  bool? enabled,
}) => HookBuilder(
  builder: (context) {
    final states = useWidgetStatesController();
    final observation = useWidgetStateObservation(states);
    return ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: observation,
      builder: (context, values, child) => PresentationInteractionScope(
        value: PresentationInteraction.fromWidgetStates(values).copyWith(
          disabled:
              values.contains(WidgetState.disabled) ||
              !(enabled ?? scope.canExecuteAction),
          readOnly: scope.readOnly,
        ),
        child: Builder(
          builder: (context) {
            try {
              final input = appearance?.appearance;
              final resolved = _controlStyle(context, scope, input);
              final layers = [
                ...scope.appearanceLayers.map((layer) => layer.appearance),
                ?input,
              ];
              bool has<T>(T? Function(skir.InputAppearance) select) =>
                  layers.any((layer) => select(layer) != null);
              final border = resolved.decoration.border;
              final style = ButtonStyle(
                textStyle: has((a) => a.valueStyle)
                    ? WidgetStatePropertyAll(resolved.valueStyle)
                    : null,
                foregroundColor: has((a) => a.valueStyle?.color)
                    ? WidgetStatePropertyAll(resolved.valueStyle.color)
                    : null,
                iconColor: has((a) => a.iconColor)
                    ? WidgetStatePropertyAll(resolved.iconColor)
                    : null,
                iconSize: has((a) => a.iconSize)
                    ? WidgetStatePropertyAll(resolved.iconSize)
                    : null,
                padding: resolved.padding == null
                    ? null
                    : WidgetStatePropertyAll(resolved.padding),
                visualDensity: resolved.dense == null
                    ? null
                    : resolved.dense!
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                backgroundColor: resolved.decoration.fillColor == null
                    ? null
                    : WidgetStatePropertyAll(resolved.decoration.fillColor),
                side: has((a) => a.border)
                    ? WidgetStatePropertyAll(
                        border?.borderSide ?? BorderSide.none,
                      )
                    : null,
                shape: has((a) => a.radius) && border is OutlineInputBorder
                    ? WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: border.borderRadius,
                        ),
                      )
                    : null,
              );
              final result = builder(context, states, style, resolved);
              final tooltip = _actionText(scope, appearance?.tooltip);
              return tooltip == null
                  ? result
                  : Tooltip(message: tooltip, child: result);
            } on PresentationColorFailure catch (failure) {
              return _diagnostic(failure.message);
            }
          },
        ),
      ),
    );
  },
);

BoxConstraints? _popupConstraints(
  PortablePresentationScope scope,
  skir.PopupAppearance? popup,
) {
  if (popup == null) return null;
  double? dimension(skir.ExpressionNode? value) {
    if (value == null) return null;
    final number = _number(scope, value);
    if (number == null || !number.isFinite || number < 0) {
      throw const PresentationColorFailure(
        "Popup dimensions must be finite and nonnegative",
      );
    }
    return number;
  }

  final minimum = dimension(popup.minimumWidth) ?? 0;
  final maximum = dimension(popup.maximumWidth) ?? double.infinity;
  final extent = dimension(popup.maximumExtent) ?? double.infinity;
  if (minimum > maximum) {
    throw const PresentationColorFailure(
      "Popup minimum width exceeds its maximum width",
    );
  }
  return BoxConstraints(
    minWidth: minimum,
    maxWidth: maximum,
    maxHeight: extent,
  );
}

OutlinedBorder? _popupShape(
  BuildContext context,
  PortablePresentationScope scope,
  skir.PopupAppearance? popup,
) {
  if (popup == null || (popup.border == null && popup.radius == null)) {
    return null;
  }
  final border = popup.border;
  if (border != null && border is! skir.PresentationBorder_allWrapper) {
    throw const PresentationColorFailure(
      "Popup borders must use one uniform side",
    );
  }
  return RoundedRectangleBorder(
    side: border == null
        ? BorderSide.none
        : _borderSide(
            context,
            (border as skir.PresentationBorder_allWrapper).value,
            scope,
          ),
    borderRadius: popup.radius == null
        ? BorderRadius.zero
        : _radius(context, popup.radius!, scope) ?? BorderRadius.zero,
  );
}

extension _ConfiguredMenuItemRendering on skir.MenuItem {
  Widget renderConfigured(PortablePresentationScope scope) => HookBuilder(
    builder: (context) {
      final states = useWidgetStatesController();
      final observation = useWidgetStateObservation(states);
      return ValueListenableBuilder<Set<WidgetState>>(
        valueListenable: observation,
        builder: (context, observed, child) => PresentationInteractionScope(
          value: PresentationInteraction.fromWidgetStates(observed)
              .copyWith(readOnly: scope.readOnly),
          child: Builder(
            builder: (context) {
              try {
                final callback = action;
                if (callback == null) {
                  return _diagnostic("A menu action is missing");
                }
                final itemLabel = _actionText(scope, label)!;
                final detail = _actionText(scope, description);
                final reason = _actionText(scope, disabledReason);
                final condition = _boolean(scope, enabledIf, fallback: true);
                if (condition case _ResolvedFailure(:final message)) {
                  return _diagnostic(message);
                }
                final enabled =
                    scope.canExecuteActionFor(callback) &&
                    (condition as _ResolvedValue<bool>).value;
                return MenuItemButton(
                  statesController: states,
                  leadingIcon: icon == null
                      ? null
                      : PortablePresentationNodeRenderer(
                          node: icon!,
                          scope: scope,
                        ),
                  onPressed: enabled
                      ? () => unawaited(scope.executeAction(callback))
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemLabel),
                      if (detail != null) Text(detail),
                      if (!enabled && reason != null) Text(reason),
                    ],
                  ),
                );
              } on PresentationColorFailure catch (failure) {
                return _diagnostic(failure.message);
              }
            },
          ),
        ),
      );
    },
  );
}
