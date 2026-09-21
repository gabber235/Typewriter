import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Establishes the common boundary between a bound control and its leaf UI.
///
/// The shell reads the binding snapshot from [scope], preserves loading and
/// invalid states as diagnostics, derives representation or nominal type
/// shape, and creates the field's interaction coordinator. The enclosing
/// scope remains authoritative for draft state, write routing, and read only
/// policy. Leaf renderers receive [BoundControlField] only after these checks,
/// so they do not duplicate access or lifecycle decisions.
///
/// [builder] must not call hooks. The shell can return before invoking it, and
/// conditional hook calls would make hook order unstable.
class BoundControlShell extends HookWidget {
  const BoundControlShell({
    required this.control,
    required this.scope,
    required this.builder,
    this.shapeMismatch,
    this.labeled = true,
    this.nominal = false,
    this.synthesizeMissingDiagnostic = true,
    super.key,
  });

  final BoundControl control;
  final PresentationRenderScope scope;

  /// Whether the shell supplies the control label and description wrapper.
  /// Set this to false when an outer surface, such as a collection header,
  /// already owns that chrome.
  final bool labeled;

  /// Whether shape checks use the declared nominal type instead of its
  /// representation type.
  final bool nominal;

  /// Whether a missing binding without a placed diagnostic receives the
  /// generic required value message.
  final bool synthesizeMissingDiagnostic;

  /// Returns a diagnostic message when the resolved binding does not have
  /// the shape this control requires.
  final String? Function(InspectedBinding binding)? shapeMismatch;

  final Widget Function(BuildContext context, BoundControlField field) builder;

  @override
  Widget build(BuildContext context) {
    final interaction = useEditorFieldInteraction(scope, control.binding);
    final resolved = scope.inspect(control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final declared = resolved.valueOrNull!;
    if (declared.value case InvalidEditorValue(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    if (declared.value is LoadingEditorValue) {
      return LabeledControl(
        control: control,
        scope: scope,
        child: const LinearProgressIndicator(),
      );
    }
    final binding = declared.copyWith(
      type: nominal
          ? declared.type.bindingNominal(scope.registry)
          : declared.type.bindingRepresentation(scope.registry),
    );
    if (shapeMismatch?.call(binding) case final message?) {
      return presentationDiagnostic(context, [
        TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
      ]);
    }

    final field = BoundControlField._(
      scope: scope,
      binding: binding,
      interaction: interaction,
      enabled: scope.enabled && binding.writable,
      readOnly: scope.readOnly,
    );

    final child = builder(context, field);
    final focusableChild = _FocusableBoundControl(
      controller: scope.bindingFocusController,
      owner: scope.editOwnerFor?.call(binding.reference),
      reference: scope.canonical(binding.reference),
      child: child,
    );

    if (!labeled) return focusableChild;
    return LabeledControl(
      control: control,
      scope: scope,
      missing: synthesizeMissingDiagnostic && field.missing,
      child: focusableChild,
    );
  }
}

class _FocusableBoundControl extends StatefulWidget {
  const _FocusableBoundControl({
    required this.controller,
    required this.owner,
    required this.reference,
    required this.child,
  });

  final RenderedBindingFocusController? controller;
  final EditOwner? owner;
  final BindingReference reference;
  final Widget child;

  @override
  State<_FocusableBoundControl> createState() => _FocusableBoundControlState();
}

class _FocusableBoundControlState extends State<_FocusableBoundControl> {
  final _focusNode = FocusNode(debugLabel: "Rendered editor binding");
  VoidCallback? _unregister;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(_FocusableBoundControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.owner != widget.owner ||
        oldWidget.reference != widget.reference) {
      _register();
    }
  }

  void _register() {
    _unregister?.call();
    _unregister = switch ((widget.controller, widget.owner)) {
      (final controller?, final owner?) => controller.register(
        owner: owner,
        reference: widget.reference,
        node: _focusNode,
      ),
      _ => null,
    };
  }

  @override
  void dispose() {
    _unregister?.call();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _focusNode, skipTraversal: true, child: widget.child);
}

/// The checked binding and interaction capabilities passed to a leaf control.
///
/// This object is an immutable view for one build. [update] routes through the
/// scope, while [editable] combines scope enablement, binding writability, and
/// read only mode. A leaf must not retain the object after building or mutate
/// the binding directly.
final class BoundControlField {
  const BoundControlField._({
    required this._scope,
    required this.binding,
    required this.interaction,
    required this.enabled,
    required this.readOnly,
  });

  final PresentationRenderScope _scope;
  final InspectedBinding binding;
  final EditorFieldInteraction interaction;
  final bool enabled;
  final bool readOnly;

  bool get editable => enabled && !readOnly;
  bool get locked => !editable;
  bool get mixed => binding.value is MixedEditorValue;
  bool get missing => binding.value is MissingEditorValue;

  /// The concrete value when the binding is ready. Loading, mixed, and invalid
  /// states are intentionally represented by [binding] instead.
  DataValue? get value => binding.value.valueOrNull;

  /// Submits a validated leaf value to the scope's binding owner.
  void update(DataValue value) => _scope.update(binding.reference, value);
}
