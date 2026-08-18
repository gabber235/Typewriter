part of "header_renderer.dart";

@freezed
sealed class _ResolvedHeaderItem with _$ResolvedHeaderItem {
  const factory _ResolvedHeaderItem.button({
    required HeaderItemId id,
    required IconValue icon,
    required String label,
    required String tooltip,
    required EditorAction action,
    required int priority,
    required int declarationOrder,
    required bool visible,
    required bool enabled,
    required HeaderActionPlacement placement,
    required HeaderActionTone tone,
    required _ResolvedConfirmation? confirmation,
  }) = _ResolvedHeaderButtonItem;

  const factory _ResolvedHeaderItem.booleanToggle({
    required HeaderItemId id,
    required String label,
    required String tooltip,
    required bool checked,
    required EditorAction action,
    required int priority,
    required int declarationOrder,
    required bool visible,
    required bool enabled,
    required HeaderActionPlacement placement,
    required _ResolvedConfirmation? confirmation,
  }) = _ResolvedHeaderBooleanToggleItem;

  const factory _ResolvedHeaderItem.reorderHandle({
    required HeaderItemId id,
    required String label,
    required String tooltip,
    required BindingReference source,
    required int index,
    required int itemCount,
    required int declarationOrder,
    required bool visible,
    required bool enabled,
  }) = _ResolvedHeaderReorderHandleItem;

  const _ResolvedHeaderItem._();

  int get priority => switch (this) {
    _ResolvedHeaderButtonItem(:final priority) ||
    _ResolvedHeaderBooleanToggleItem(:final priority) => priority,
    _ResolvedHeaderReorderHandleItem() => 0,
  };

  @override
  int get declarationOrder => switch (this) {
    _ResolvedHeaderButtonItem(:final declarationOrder) ||
    _ResolvedHeaderBooleanToggleItem(:final declarationOrder) ||
    _ResolvedHeaderReorderHandleItem(
      :final declarationOrder,
    ) => declarationOrder,
  };

  @override
  HeaderItemId get id => switch (this) {
    _ResolvedHeaderButtonItem(:final id) ||
    _ResolvedHeaderBooleanToggleItem(:final id) ||
    _ResolvedHeaderReorderHandleItem(:final id) => id,
  };

  @override
  String get label => switch (this) {
    _ResolvedHeaderButtonItem(:final label) ||
    _ResolvedHeaderBooleanToggleItem(:final label) ||
    _ResolvedHeaderReorderHandleItem(:final label) => label,
  };

  @override
  String get tooltip => switch (this) {
    _ResolvedHeaderButtonItem(:final tooltip) ||
    _ResolvedHeaderBooleanToggleItem(:final tooltip) ||
    _ResolvedHeaderReorderHandleItem(:final tooltip) => tooltip,
  };

  @override
  bool get visible => switch (this) {
    _ResolvedHeaderButtonItem(:final visible) ||
    _ResolvedHeaderBooleanToggleItem(:final visible) ||
    _ResolvedHeaderReorderHandleItem(:final visible) => visible,
  };

  @override
  bool get enabled => switch (this) {
    _ResolvedHeaderButtonItem(:final enabled) ||
    _ResolvedHeaderBooleanToggleItem(:final enabled) ||
    _ResolvedHeaderReorderHandleItem(:final enabled) => enabled,
  };

  HeaderActionPlacement? get placement => switch (this) {
    _ResolvedHeaderButtonItem(:final placement) ||
    _ResolvedHeaderBooleanToggleItem(:final placement) => placement,
    _ResolvedHeaderReorderHandleItem() => null,
  };
}

@freezed
abstract class _ResolvedPresentationHeader with _$ResolvedPresentationHeader {
  const factory _ResolvedPresentationHeader({
    required PresentationHeaderTitle? title,
    required String description,
    required List<_ResolvedHeaderItem> items,
  }) = _ResolvedPresentationHeaderValue;
}

extension on PresentationHeader {
  _ResolvedPresentationHeader resolve(PresentationRenderScope scope) {
    return _ResolvedPresentationHeader(
      title: title,
      description: description == null
          ? ""
          : scope.expressionText(description!),
      items: [
        for (final (index, item) in items.indexed) item.resolve(scope, index),
      ],
    );
  }
}

extension on _ResolvedHeaderReorderHandleItem {
  int? _destination(HeaderItemCommand command) =>
      _reorderDestination(command, index, itemCount);

  String _commandLabel(HeaderItemCommand command) => switch (command) {
    HeaderItemCommand.moveBefore => "Move $label before",
    HeaderItemCommand.moveAfter => "Move $label after",
    HeaderItemCommand.moveToStart => "Move $label to start",
    HeaderItemCommand.moveToEnd => "Move $label to end",
    HeaderItemCommand.activate => label,
  };

  void _move(PresentationRenderScope scope, HeaderItemCommand command) {
    if (!enabled) return;
    final diagnostics = <TypeDiagnostic>[];
    final canonical = scope.canonical(source);
    final location = canonical._listItemLocation(scope, diagnostics);
    if (location == null) return;
    final destination = _reorderDestination(command, location.$1, location.$2);
    if (destination == null) return;
    scope.invoke(
      LocalEditorAction(
        ReorderListItemAction(
          source: canonical,
          newIndex: destination.asSigned64Literal,
        ),
      ),
    );
  }
}

int? _reorderDestination(HeaderItemCommand command, int index, int itemCount) =>
    switch (command) {
      HeaderItemCommand.moveBefore when index > 0 => index - 1,
      HeaderItemCommand.moveAfter when index < itemCount - 1 => index + 1,
      HeaderItemCommand.moveToStart when index > 0 => 0,
      HeaderItemCommand.moveToEnd when index < itemCount - 1 => itemCount - 1,
      _ => null,
    };

@freezed
abstract class _ResolvedConfirmation with _$ResolvedConfirmation {
  const factory _ResolvedConfirmation({
    required String title,
    required String message,
    required String confirmationLabel,
  }) = _ResolvedConfirmationValue;
}

extension on HeaderItem {
  _ResolvedHeaderItem resolve(
    PresentationRenderScope scope,
    int declarationOrder,
  ) => switch (this) {
    final HeaderButtonItem item => item._resolve(scope, declarationOrder),
    final HeaderBooleanToggleItem item => item._resolve(
      scope,
      declarationOrder,
    ),
    final HeaderReorderHandleItem item => item._resolve(
      scope,
      declarationOrder,
    ),
  };
}

extension on HeaderButtonItem {
  _ResolvedHeaderItem _resolve(
    PresentationRenderScope scope,
    int declarationOrder,
  ) {
    final diagnostics = <TypeDiagnostic>[];
    final resolvedIcon = icon._icon(scope, diagnostics);
    final resolvedConfirmation = confirmation?._resolve(scope, diagnostics);
    final resolved = _resolveCommon(
      scope,
      declarationOrder,
      diagnostics,
      action: action,
    );
    return _ResolvedHeaderItem.button(
      id: id,
      icon: resolvedIcon ?? const IconValue.svg(MaterialSymbols.error_rounded),
      label: resolved.label,
      tooltip: resolved.tooltip,
      action: action,
      priority: resolved.priority,
      declarationOrder: declarationOrder,
      visible: resolved.visible,
      enabled: resolved.enabled,
      placement: placement,
      tone: tone,
      confirmation: resolvedConfirmation,
    );
  }
}

extension on HeaderBooleanToggleItem {
  _ResolvedHeaderItem _resolve(
    PresentationRenderScope scope,
    int declarationOrder,
  ) {
    final diagnostics = <TypeDiagnostic>[];
    final resolvedChecked = this.checked._boolean(scope, diagnostics);
    final resolvedConfirmation = confirmation?._resolve(scope, diagnostics);
    final resolved = _resolveCommon(
      scope,
      declarationOrder,
      diagnostics,
      action: action,
    );
    return _ResolvedHeaderItem.booleanToggle(
      id: id,
      label: resolved.label,
      tooltip: resolved.tooltip,
      checked: resolvedChecked,
      action: action,
      priority: resolved.priority,
      declarationOrder: declarationOrder,
      visible: resolved.visible,
      enabled: resolved.enabled,
      placement: placement,
      confirmation: resolvedConfirmation,
    );
  }
}

extension on HeaderReorderHandleItem {
  _ResolvedHeaderItem _resolve(
    PresentationRenderScope scope,
    int declarationOrder,
  ) {
    final diagnostics = <TypeDiagnostic>[];
    final resolved = _resolveCommon(scope, declarationOrder, diagnostics);
    final canonical = scope.canonical(source);
    final location = canonical._listItemLocation(scope, diagnostics);
    return _ResolvedHeaderItem.reorderHandle(
      id: id,
      label: resolved.label,
      tooltip: diagnostics.isEmpty
          ? resolved.tooltip
          : diagnostics.map((item) => item.message).join("\n"),
      source: canonical,
      index: location?.$1 ?? 0,
      itemCount: location?.$2 ?? 0,
      declarationOrder: declarationOrder,
      visible: resolved.visible,
      enabled: resolved.enabled && diagnostics.isEmpty && !scope.readOnly,
    );
  }
}

extension on HeaderItem {
  _ResolvedHeaderItemCommon _resolveCommon(
    PresentationRenderScope scope,
    int declarationOrder,
    List<TypeDiagnostic> diagnostics, {
    EditorAction? action,
  }) {
    final label = switch (this) {
      HeaderButtonItem(:final label) ||
      HeaderBooleanToggleItem(:final label) ||
      HeaderReorderHandleItem(:final label) => label,
    };
    final tooltip = switch (this) {
      HeaderButtonItem(:final tooltip) ||
      HeaderBooleanToggleItem(:final tooltip) ||
      HeaderReorderHandleItem(:final tooltip) => tooltip,
    };
    final priority = switch (this) {
      HeaderButtonItem(:final priority) ||
      HeaderBooleanToggleItem(:final priority) => priority,
      HeaderReorderHandleItem() => null,
    };
    final visibleIf = switch (this) {
      HeaderButtonItem(:final visibleIf) ||
      HeaderBooleanToggleItem(:final visibleIf) ||
      HeaderReorderHandleItem(:final visibleIf) => visibleIf,
    };
    final enabledIf = switch (this) {
      HeaderButtonItem(:final enabledIf) ||
      HeaderBooleanToggleItem(:final enabledIf) ||
      HeaderReorderHandleItem(:final enabledIf) => enabledIf,
    };
    final resolvedLabel = label._string(scope, diagnostics);
    final resolvedTooltip =
        tooltip?._string(scope, diagnostics) ?? resolvedLabel;
    final resolvedPriority = priority?._integer(scope, diagnostics) ?? 0;
    final resolvedVisible = visibleIf?._boolean(scope, diagnostics) ?? true;
    final resolvedEnabled = enabledIf?._boolean(scope, diagnostics) ?? true;
    final actionAllowed =
        action == null || !(scope.readOnly && action is LocalEditorAction);
    return (
      label: diagnostics.isEmpty ? resolvedLabel : "Invalid item",
      tooltip: diagnostics.isEmpty
          ? resolvedTooltip
          : diagnostics.map((item) => item.message).join("\n"),
      priority: resolvedPriority,
      visible: diagnostics.isNotEmpty || resolvedVisible,
      enabled:
          diagnostics.isEmpty &&
          resolvedEnabled &&
          scope.enabled &&
          actionAllowed,
    );
  }
}

typedef _ResolvedHeaderItemCommon = ({
  String label,
  String tooltip,
  int priority,
  bool visible,
  bool enabled,
});

extension on BindingReference {
  (int, int)? _listItemLocation(
    PresentationRenderScope scope,
    List<TypeDiagnostic> diagnostics,
  ) {
    final segment = path.segments.lastOrNull;
    if (segment is! IndexPathSegment) {
      diagnostics.add(
        _invalidHeaderValue("Reorder source must be a list item binding"),
      );
      return null;
    }
    final index = segment.index;
    final parent = BindingReference(
      bindingId: bindingId,
      path: DataPath(path.segments.sublist(0, path.segments.length - 1)),
    );
    final resolved = scope.resolve(parent);
    diagnostics.addAll(resolved.diagnostics);
    if (resolved.valueOrNull case ResolvedBinding(
      type: ListType(),
      value: ListValue(:final values),
    )) {
      if (index < values.length) return (index, values.length);
    }
    diagnostics.add(
      _invalidHeaderValue("Reorder source parent must be a list"),
    );
    return null;
  }
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
