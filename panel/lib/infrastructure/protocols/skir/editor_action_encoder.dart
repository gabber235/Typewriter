import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as wire_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire_diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as wire_expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirActionEncoder {
  const SkirActionEncoder(this.expressions, this.values);

  final SkirExpressionEncoder expressions;
  final SkirDataValueCodec values;

  TypeResult<wire.EditorAction> encode(EditorAction value) => switch (value) {
    LocalEditorAction(:final action) => _local(
      action,
    ).mapValue(wire.EditorAction.wrapLocal),
    RealmEditorAction(:final action) => _realm(
      action,
    ).mapValue(wire.EditorAction.wrapRealm),
  };

  TypeResult<wire.TypedMutationResult> encodeMutation(
    TypedMutationResult value,
  ) => switch (value) {
    MutationSuccess() =>
      values
          .encode(value.value)
          .mapValue(
            (encoded) => wire.TypedMutationResult.createSuccess(
              revision: value.revision,
              value: encoded,
            ),
          ),
    MutationConflict() =>
      values
          .encode(value.actualValue)
          .mapValue(
            (encoded) => wire.TypedMutationResult.createConflict(
              expectedRevision: value.expectedRevision,
              actualRevision: value.actualRevision,
              actualValue: encoded,
            ),
          ),
    MutationInvalid(:final diagnostics) => TypeResult.success(
      wire.TypedMutationResult.wrapInvalid(_diagnostics(diagnostics)),
    ),
    MutationUnavailable(:final diagnostics) => TypeResult.success(
      wire.TypedMutationResult.wrapUnavailable(_diagnostics(diagnostics)),
    ),
    MutationPermissionDenied(:final message) => TypeResult.success(
      wire.TypedMutationResult.createPermissionDenied(message: message),
    ),
  };

  List<wire_diagnostic.TypeDiagnostic> _diagnostics(
    Iterable<TypeDiagnostic> values,
  ) => [
    for (final value in values)
      value.encodeWire(SkirDataPathCodec(this.values)),
  ];

  TypeResult<wire.LocalEditorAction> _local(
    LocalAction value,
  ) => switch (value) {
    SetValueAction() => _targetExpression(
      value.target,
      value.value,
      (target, expression) => wire.LocalEditorAction.createSetValue(
        target: target,
        value: expression,
      ),
    ),
    InsertListItemAction() => _insert(value),
    RemoveListItemAction() => _targetExpression(
      value.target,
      value.index,
      (target, index) => wire.LocalEditorAction.createRemoveListItem(
        target: target,
        index: index,
      ),
    ),
    AppendListItemAction() => _targetExpression(
      value.target,
      value.value,
      (target, item) => wire.LocalEditorAction.createAppendListItem(
        target: target,
        value: item,
      ),
    ),
    DuplicateListItemAction() =>
      expressions
          .binding(value.source)
          .mapValue(
            (source) =>
                wire.LocalEditorAction.createDuplicateListItem(source: source),
          ),
    ReorderListItemAction() => _targetExpression(
      value.source,
      value.newIndex,
      (source, newIndex) => wire.LocalEditorAction.createReorderListItem(
        source: source,
        newIndex: newIndex,
      ),
    ),
    PutMapEntryAction() => _put(value),
    RemoveMapEntryAction() => _targetExpression(
      value.target,
      value.key,
      (target, key) =>
          wire.LocalEditorAction.createRemoveMapEntry(target: target, key: key),
    ),
    ReplaceConcreteTypeAction() => _replace(value),
  };

  TypeResult<wire.LocalEditorAction> _put(PutMapEntryAction value) {
    final target = expressions.binding(value.target);
    final key = expressions.encode(value.key);
    final item = expressions.encode(value.value);
    return combineThreeResults(
      target,
      key,
      item,
      (target, key, item) => wire.LocalEditorAction.createPutMapEntry(
        target: target,
        key: key,
        value: item,
      ),
    );
  }

  TypeResult<wire.LocalEditorAction> _replace(ReplaceConcreteTypeAction value) {
    final target = expressions.binding(value.target);
    final type = values.typeCodec.encodeReference(value.concreteType);
    final initial = expressions.encode(value.initialValue);
    return combineThreeResults(
      target,
      type,
      initial,
      (target, type, initial) =>
          wire.LocalEditorAction.createReplaceConcreteNominalType(
            target: target,
            concreteType: type,
            value: initial,
          ),
    );
  }

  TypeResult<wire.RealmEditorAction> _realm(RealmAction value) =>
      switch (value) {
        ReloadRealmAction() => TypeResult.success(
          wire.RealmEditorAction.createReload(),
        ),
        InvokeRealmCommandAction() =>
          expressions
              .encode(value.payload)
              .mapValue(
                (payload) => wire.RealmEditorAction.createCommand(
                  capabilityId: wire_type.CapabilityId(
                    value: value.capabilityId.value,
                  ),
                  payload: payload,
                ),
              ),
      };

  TypeResult<wire.LocalEditorAction> _targetExpression(
    BindingReference target,
    TypedExpression expression,
    wire.LocalEditorAction Function(
      wire_binding.BindingRef target,
      wire_expression.TypedExpression expression,
    )
    create,
  ) => combineResults(
    expressions.binding(target),
    expressions.encode(expression),
    create,
  );

  TypeResult<wire.LocalEditorAction> _insert(InsertListItemAction value) {
    final target = expressions.binding(value.target);
    final index = expressions.encode(value.index);
    final item = expressions.encode(value.value);
    return combineThreeResults(
      target,
      index,
      item,
      (target, index, item) => wire.LocalEditorAction.createInsertListItem(
        target: target,
        index: index,
        value: item,
      ),
    );
  }
}
