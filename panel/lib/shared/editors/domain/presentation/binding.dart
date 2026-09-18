/// Typed references into values exposed by an editor host.
///
/// A binding source owns the current value, revision, and write authority.
/// [BindingEnvironment] only resolves paths and returns replacement snapshots,
/// so presentations and expressions can share a consistent read model without
/// taking ownership of mutable editor state.
library;

import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "binding.freezed.dart";

@freezed
abstract class BindingId with _$BindingId {
  @Assert("value >= 0", "Binding ID must not be negative.")
  const factory BindingId(int value) = _BindingId;
}

/// A binding identifier plus a path inside the bound root value.
///
/// Root references identify the complete value. [at] composes a child path for
/// nested fields or collection entries while retaining the same root owner.
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
abstract class BindingSnapshot with _$BindingSnapshot implements BindingSource {
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

  @override
  TypeResult<BindingSourceState> inspect(
    DataPath path, {
    TypeRegistry? registry,
  }) =>
      EditorValue.ready(value)
          .inspectBindingValue(type, path, registry: registry);
}

/// Exposes typed path state without requiring one concrete value.
///
/// Projection preserves live value state, revision, and writability. Use
/// [BindingEnvironment.inspect] for structure and value state. Use
/// [BindingEnvironment.resolve] only when the caller requires one value.
/// Read access to a binding while preserving its revision and write authority.
///
/// Implementations may expose a ready value, loading state, mixed values, or
/// diagnostics. [inspect] is therefore the structural API; callers should use
/// [BindingEnvironment.resolve] only when one concrete value is required.
abstract interface class BindingSource {
  int get revision;
  bool get writable;

  TypeResult<BindingSourceState> inspect(
    DataPath path, {
    TypeRegistry? registry,
  });
}

extension BindingSourceProjection on BindingSource {
  BindingSource withRootType(TypeExpression type) =>
      _RetypedBindingSource(source: this, rootType: type);
}

@freezed
abstract class BindingSourceState with _$BindingSourceState {
  const factory BindingSourceState({
    required TypeExpression type,
    required EditorValue value,
  }) = _BindingSourceState;
}

@freezed
abstract class InspectedBinding with _$InspectedBinding {
  const factory InspectedBinding({
    required BindingReference reference,
    required TypeExpression type,
    required EditorValue value,
    required int revision,
    required bool writable,
  }) = _InspectedBinding;
}

extension InspectedBindingValue on InspectedBinding {
  ResolvedBinding? get resolvedOrNull {
    final current = value.valueOrNull;
    if (current == null) return null;
    return ResolvedBinding(
      reference: reference,
      type: type,
      value: current,
      revision: revision,
      writable: writable,
    );
  }
}

final class EditorValueBindingSource implements BindingSource {
  const EditorValueBindingSource({
    required this.type,
    required this.value,
    required this.revision,
    this.writable = false,
  });

  final TypeExpression type;
  final EditorValue value;
  @override
  final int revision;
  @override
  final bool writable;

  @override
  TypeResult<BindingSourceState> inspect(
    DataPath path, {
    TypeRegistry? registry,
  }) => value.inspectBindingValue(type, path, registry: registry);
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

/// Immutable lookup and replacement boundary for presentation bindings.
///
/// The environment delegates ownership to its [BindingSource] entries. Path
/// inspection preserves non ready states and metadata, while replacement
/// updates one root snapshot and increments that source revision.
@freezed
abstract class BindingEnvironment with _$BindingEnvironment {
  const factory BindingEnvironment(Map<BindingId, BindingSource> bindings) =
      _BindingEnvironment;

  const BindingEnvironment._();

  TypeResult<InspectedBinding> inspect(
    BindingReference reference, {
    TypeRegistry? registry,
  }) {
    final source = bindings[reference.bindingId];
    if (source == null) return _failure("Binding is not available");
    final state = source.inspect(reference.path, registry: registry);
    if (state case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final inspected = state.valueOrNull!;
    return TypeResult.success(
      InspectedBinding(
        reference: reference,
        type: inspected.type,
        value: inspected.value,
        revision: source.revision,
        writable: source.writable,
      ),
    );
  }

  TypeResult<ResolvedBinding> resolve(
    BindingReference reference, {
    TypeRegistry? registry,
  }) {
    final inspected = inspect(reference, registry: registry);
    if (inspected case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final binding = inspected.valueOrNull!;
    return switch (binding.value) {
      ReadyEditorValue(:final value) => TypeResult.success(
        ResolvedBinding(
          reference: binding.reference,
          type: binding.type,
          value: value,
          revision: binding.revision,
          writable: binding.writable,
        ),
      ),
      LoadingEditorValue() => _failure("Binding is loading"),
      MissingEditorValue() => _failure("Binding has no value yet"),
      MixedEditorValue() => _failure("Binding has different values"),
      InvalidEditorValue(:final diagnostics) => TypeResult.failure(diagnostics),
    };
  }

  TypeResult<BindingEnvironment> replace(
    BindingReference reference,
    DataValue replacement, {
    TypeRegistry? registry,
  }) {
    final rootReference = BindingReference(bindingId: reference.bindingId);
    final root = resolve(rootReference, registry: registry);
    if (root case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final binding = root.valueOrNull!;
    if (!binding.writable) return _failure("Binding is read only");
    final replaced = reference.path.replace(binding.value, replacement);
    if (replaced case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      BindingEnvironment({
        ...bindings,
        reference.bindingId: BindingSnapshot(
          type: binding.type,
          value: replaced.valueOrNull!,
          revision: binding.revision + 1,
          writable: true,
        ),
      }),
    );
  }

  TypeResult<BindingSource> project(
    BindingReference reference, {
    TypeRegistry? registry,
  }) {
    final inspected = inspect(reference, registry: registry);
    if (inspected case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      _ProjectedBindingSource(
        source: bindings[reference.bindingId]!,
        prefix: reference.path,
      ),
    );
  }
}

final class _ProjectedBindingSource implements BindingSource {
  const _ProjectedBindingSource({required this.source, required this.prefix});

  final BindingSource source;
  final DataPath prefix;

  @override
  int get revision => source.revision;

  @override
  bool get writable => source.writable;

  @override
  TypeResult<BindingSourceState> inspect(
    DataPath path, {
    TypeRegistry? registry,
  }) => source.inspect(prefix.followedBy(path), registry: registry);
}

final class _RetypedBindingSource implements BindingSource {
  const _RetypedBindingSource({required this.source, required this.rootType});

  final BindingSource source;
  final TypeExpression rootType;

  @override
  int get revision => source.revision;

  @override
  bool get writable => source.writable;

  @override
  TypeResult<BindingSourceState> inspect(
    DataPath path, {
    TypeRegistry? registry,
  }) {
    final state = source.inspect(path, registry: registry);
    if (state case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final type = rootType.resolvePath(path, registry: registry);
    if (type case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      BindingSourceState(
        type: type.valueOrNull!,
        value: state.valueOrNull!.value,
      ),
    );
  }
}

extension BindingSourceInspection on EditorValue {
  TypeResult<BindingSourceState> inspectBindingValue(
    TypeExpression rootType,
    DataPath path, {
    TypeRegistry? registry,
  }) {
    final type = rootType.resolvePath(path, registry: registry);
    if (type case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final inspected = switch (this) {
      ReadyEditorValue(:final value) => value.readEditorValue(path),
      LoadingEditorValue() => const EditorValue.loading(),
      MissingEditorValue() => const EditorValue.missing(),
      MixedEditorValue() => const EditorValue.mixed(),
      InvalidEditorValue(:final diagnostics) => EditorValue.invalid(
        diagnostics,
      ),
    };
    return TypeResult.success(
      BindingSourceState(type: type.valueOrNull!, value: inspected),
    );
  }
}

TypeFailure<T> _failure<T>(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidPath, message: message),
]);

extension BindingTypeResolution on TypeExpression {
  TypeExpression bindingNominal(TypeRegistry registry) {
    var current = this;
    final visited = <ResolvedTypeRef>{};
    while (current is NamedType && visited.add(current.reference)) {
      final next = registry.resolve(current).valueOrNull?.representation;
      if (next is! NamedType) break;
      current = next;
    }
    return current;
  }

  TypeExpression bindingRepresentation(TypeRegistry? registry) {
    var current = this;
    final visited = <ResolvedTypeRef>{};
    while (registry != null &&
        current is NamedType &&
        visited.add(current.reference)) {
      final next = registry.resolve(current).valueOrNull?.representation;
      if (next == null) break;
      current = next;
    }
    return current;
  }
}
