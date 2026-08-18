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

final class SkirActionDecoder {
  const SkirActionDecoder(this.expressions, this.values);

  final SkirExpressionDecoder expressions;
  final SkirDataValueCodec values;

  SkirTypeCodec get types => values.typeCodec;

  TypeResult<EditorAction> decode(wire.EditorAction value) => switch (value) {
    wire.EditorAction_localWrapper(:final value) => _local(
      value,
    ).mapValue(EditorAction.local),
    wire.EditorAction_realmWrapper(:final value) => _realm(
      value,
    ).mapValue(EditorAction.realm),
    wire.EditorAction_unknown() => invalidWire("Unknown editor action"),
  };

  TypeResult<TypedMutationResult> decodeMutation(
    wire.TypedMutationResult value,
  ) => switch (value) {
    wire.TypedMutationResult_successWrapper(:final value) =>
      value.revision < 0
          ? invalidWire("Mutation revision is negative")
          : values
                .decode(value.value)
                .mapValue(
                  (decoded) =>
                      MutationSuccess(revision: value.revision, value: decoded),
                ),
    wire.TypedMutationResult_conflictWrapper(:final value) =>
      value.expectedRevision < 0 || value.actualRevision < 0
          ? invalidWire("Mutation conflict revision is negative")
          : values
                .decode(value.actualValue)
                .mapValue(
                  (decoded) => MutationConflict(
                    expectedRevision: value.expectedRevision,
                    actualRevision: value.actualRevision,
                    actualValue: decoded,
                  ),
                ),
    wire.TypedMutationResult_invalidWrapper(:final value) => _diagnostics(
      value,
    ).mapValue(MutationInvalid.new),
    wire.TypedMutationResult_unavailableWrapper(:final value) => _diagnostics(
      value,
    ).mapValue(MutationUnavailable.new),
    wire.TypedMutationResult_permissionDeniedWrapper(:final value) =>
      TypeResult.success(MutationPermissionDenied(value.message)),
    wire.TypedMutationResult_unknown() => invalidWire(
      "Unknown typed mutation result",
    ),
  };

  TypeResult<List<TypeDiagnostic>> _diagnostics(
    Iterable<wire_diagnostic.TypeDiagnostic> values,
  ) {
    final decoded = [
      for (final value in values)
        value.decodeWire(SkirDataPathCodec(this.values)),
    ];
    return decoded.isEmpty
        ? invalidWire("Mutation diagnostics are empty")
        : TypeResult.success(decoded);
  }

  TypeResult<LocalAction> _local(wire.LocalEditorAction value) =>
      switch (value) {
        wire.LocalEditorAction_setValueWrapper(:final value) => _combine(
          value.target,
          value.value,
          (target, expression) =>
              SetValueAction(target: target, value: expression),
        ),
        wire.LocalEditorAction_insertListItemWrapper(:final value) => _insert(
          value,
        ),
        wire.LocalEditorAction_removeListItemWrapper(:final value) => _combine(
          value.target,
          value.index,
          (target, expression) =>
              RemoveListItemAction(target: target, index: expression),
        ),
        wire.LocalEditorAction_appendListItemWrapper(:final value) => _combine(
          value.target,
          value.value,
          (target, expression) =>
              AppendListItemAction(target: target, value: expression),
        ),
        wire.LocalEditorAction_duplicateListItemWrapper(:final value) =>
          expressions
              .binding(value.source)
              .mapValue((source) => DuplicateListItemAction(source: source)),
        wire.LocalEditorAction_reorderListItemWrapper(:final value) => _combine(
          value.source,
          value.newIndex,
          (source, expression) =>
              ReorderListItemAction(source: source, newIndex: expression),
        ),
        wire.LocalEditorAction_putMapEntryWrapper(:final value) => _put(value),
        wire.LocalEditorAction_removeMapEntryWrapper(:final value) => _combine(
          value.target,
          value.key,
          (target, expression) =>
              RemoveMapEntryAction(target: target, key: expression),
        ),
        wire.LocalEditorAction_replaceConcreteNominalTypeWrapper(
          :final value,
        ) =>
          _replace(value),
        wire.LocalEditorAction_unknown() => invalidWire("Unknown local action"),
      };

  TypeResult<LocalAction> _put(wire.PutMapEntryAction value) {
    final target = expressions.binding(value.target);
    final key = expressions.decode(value.key);
    final item = expressions.decode(value.value);
    return combineThreeResults(
      target,
      key,
      item,
      (target, key, item) =>
          PutMapEntryAction(target: target, key: key, value: item),
    );
  }

  TypeResult<LocalAction> _replace(
    wire.ReplaceConcreteNominalTypeAction value,
  ) {
    final target = expressions.binding(value.target);
    final type = types.decodeReference(value.concreteType);
    final initial = expressions.decode(value.value);
    return combineThreeResults(
      target,
      type,
      initial,
      (target, type, initial) => ReplaceConcreteTypeAction(
        target: target,
        concreteType: type,
        initialValue: initial,
      ),
    );
  }

  TypeResult<RealmAction> _realm(wire.RealmEditorAction value) =>
      switch (value) {
        wire.RealmEditorAction_reloadWrapper() => const TypeResult.success(
          ReloadRealmAction(),
        ),
        wire.RealmEditorAction_callbackWrapper(:final value) => combineResults(
          value.realmActionId._decodeDomain(),
          expressions.decode(value.payload),
          (actionId, payload) =>
              InvokeRealmCallbackAction(actionId: actionId, payload: payload),
        ),
        wire.RealmEditorAction_unknown() => invalidWire("Unknown realm action"),
      };

  TypeResult<LocalAction> _combine(
    wire_binding.BindingRef target,
    wire_expression.TypedExpression expression,
    LocalAction Function(BindingReference, TypedExpression) create,
  ) => combineResults(
    expressions.binding(target),
    expressions.decode(expression),
    create,
  );

  TypeResult<LocalAction> _insert(wire.InsertListItemAction value) {
    final target = expressions.binding(value.target);
    final index = expressions.decode(value.index);
    final item = expressions.decode(value.value);
    return combineThreeResults(
      target,
      index,
      item,
      (target, index, item) =>
          InsertListItemAction(target: target, index: index, value: item),
    );
  }
}

extension on wire_type.RealmActionId {
  TypeResult<RealmActionId> _decodeDomain() {
    return namespace.isNotEmpty && name.isNotEmpty
        ? TypeResult.success(RealmActionId(namespace: namespace, name: name))
        : invalidWire("Realm action id is not qualified");
  }
}
