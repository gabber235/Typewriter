import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "binding.freezed.dart";

@freezed
abstract class BindingId with _$BindingId {
  @Assert("value >= 0", "Binding ID must not be negative.")
  const factory BindingId(int value) = _BindingId;
}

@freezed
abstract class BindingReference with _$BindingReference {
  const factory BindingReference({
    required BindingId bindingId,
    @Default(DataPath.root) DataPath path,
  }) = _BindingReference;

  const BindingReference._();

  BindingReference at(DataPath suffix) =>
      BindingReference(bindingId: bindingId, path: path.followedBy(suffix));
}

@freezed
abstract class BindingSnapshot with _$BindingSnapshot {
  @Assert("revision >= 0", "Binding revision must not be negative.")
  const factory BindingSnapshot({
    required TypeExpression type,
    required DataValue value,
    required int revision,
    @Default(true) bool writable,
  }) = _BindingSnapshot;

  const BindingSnapshot._();

  BindingSnapshot withValue(DataValue next) => BindingSnapshot(
    type: type,
    value: next,
    revision: revision + 1,
    writable: writable,
  );
}

@freezed
abstract class ResolvedBinding with _$ResolvedBinding {
  const factory ResolvedBinding({
    required BindingReference reference,
    required TypeExpression type,
    required DataValue value,
    required int revision,
    required bool writable,
  }) = _ResolvedBinding;
}

@freezed
abstract class BindingEnvironment with _$BindingEnvironment {
  const factory BindingEnvironment(Map<BindingId, BindingSnapshot> bindings) =
      _BindingEnvironment;

  const BindingEnvironment._();

  TypeResult<ResolvedBinding> resolve(BindingReference reference) {
    final snapshot = bindings[reference.bindingId];
    if (snapshot == null) return _failure("Binding is not available");
    var type = snapshot.type;
    var value = snapshot.value;
    for (final segment in reference.path.segments) {
      final next = segment._resolveBindingSegment(type, value);
      if (next case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      final resolved = next.valueOrNull!;
      type = resolved.$1;
      value = resolved.$2;
    }
    return TypeResult.success(
      ResolvedBinding(
        reference: reference,
        type: type,
        value: value,
        revision: snapshot.revision,
        writable: snapshot.writable,
      ),
    );
  }

  TypeResult<BindingEnvironment> replace(
    BindingReference reference,
    DataValue replacement,
  ) {
    final snapshot = bindings[reference.bindingId];
    if (snapshot == null) return _failure("Binding is not available");
    if (!snapshot.writable) return _failure("Binding is read only");
    final replaced = reference.path.replace(snapshot.value, replacement);
    if (replaced case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      BindingEnvironment({
        ...bindings,
        reference.bindingId: snapshot.withValue(replaced.valueOrNull!),
      }),
    );
  }
}

extension on DataPathSegment {
  TypeResult<(TypeExpression, DataValue)> _resolveBindingSegment(
    TypeExpression type,
    DataValue value,
  ) {
    final child = read(value);
    if (child case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final childType = switch ((type, this, value)) {
      (RecordType(:final fields), FieldPathSegment(:final name), _) =>
        fields[name]?.type,
      (ListType(:final element), IndexPathSegment(), _) => element,
      (MapType(value: final valueType), MapKeyPathSegment(), _) => valueType,
      _ => null,
    };
    if (childType == null) return _failure("Path does not match its type");
    return TypeResult.success((childType, child.valueOrNull!));
  }
}

TypeFailure<T> _failure<T>(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidPath, message: message),
]);
