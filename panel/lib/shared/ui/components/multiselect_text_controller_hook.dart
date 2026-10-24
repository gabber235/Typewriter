part of "multiselect_dropdown.dart";

/// Owns a controller until its hook is disposed or its keys change.
///
/// Initial text and both callbacks are captured when the controller is created.
/// Later builds do not replace them unless the hook keys change.
const useMultiSelectTextEditingController =
    _MultiSelectTextEditingControllerHookCreator();

class _MultiSelectTextEditingControllerHookCreator {
  const _MultiSelectTextEditingControllerHookCreator();

  /// Creates a [TextEditingController] that will be disposed automatically.
  ///
  /// The [text] parameter can be used to set the initial value of the
  /// controller.
  _MultiSelectTextEditingController call({
    required ChangeTags onSetLabels,
    required LabelWidgetBuilder labelWidgetBuilder,
    String? text,
    List<Object?>? keys,
  }) {
    return use(
      _MultiSelectTextEditingControllerHook(
        text,
        onSetLabels,
        labelWidgetBuilder,
        keys,
      ),
    );
  }

  /// Creates a [TextEditingController] from the initial [value] that will
  /// be disposed automatically.
  _MultiSelectTextEditingController fromValue(
    TextEditingValue value,
    ChangeTags onSetLabels,
    LabelWidgetBuilder labelWidgetBuilder, [
    List<Object?>? keys,
  ]) {
    return use(
      _MultiSelectTextEditingControllerHook.fromValue(
        value,
        onSetLabels,
        labelWidgetBuilder,
        keys,
      ),
    );
  }
}

class _MultiSelectTextEditingControllerHook
    extends Hook<_MultiSelectTextEditingController> {
  const _MultiSelectTextEditingControllerHook(
    this.initialText,
    this.onSetLabels,
    this.labelWidgetBuilder, [
    List<Object?>? keys,
  ]) : initialValue = null,
       super(keys: keys);

  const _MultiSelectTextEditingControllerHook.fromValue(
    TextEditingValue this.initialValue,
    this.onSetLabels,
    this.labelWidgetBuilder, [
    List<Object?>? keys,
  ]) : initialText = null,
       super(keys: keys);

  final String? initialText;
  final TextEditingValue? initialValue;
  final ChangeTags onSetLabels;
  final LabelWidgetBuilder labelWidgetBuilder;

  @override
  _TextEditingControllerHookState createState() {
    return _TextEditingControllerHookState();
  }
}

class _TextEditingControllerHookState
    extends
        HookState<
          _MultiSelectTextEditingController,
          _MultiSelectTextEditingControllerHook
        > {
  late final _controller = hook.initialValue != null
      ? _MultiSelectTextEditingController.fromValue(
          hook.initialValue,
          hook.onSetLabels,
          hook.labelWidgetBuilder,
        )
      : _MultiSelectTextEditingController(
          text: hook.initialText,
          onSetLabels: hook.onSetLabels,
          labelWidgetBuilder: hook.labelWidgetBuilder,
        );

  @override
  _MultiSelectTextEditingController build(BuildContext context) => _controller;

  @override
  void dispose() => _controller.dispose();

  @override
  String get debugLabel => "useMultiSelectTextEditingController";
}
