sealed class EditorValue {
  const EditorValue();

  const factory EditorValue.loading() = LoadingValue;
  const factory EditorValue.value(dynamic value) = Value;
  const factory EditorValue.conflict() = ConflictValue;
  const factory EditorValue.none() = NoneValue;

  factory EditorValue.from(dynamic value) {
    if (value == null) return const EditorValue.none();
    return EditorValue.value(value);
  }

  dynamic valueOr(dynamic defaultValue) {
    return switch (this) {
      Value(:final value) => value,
      ConflictValue() || NoneValue() || LoadingValue() => defaultValue,
    };
  }
}

final class LoadingValue extends EditorValue {
  const LoadingValue();
}

final class Value extends EditorValue {
  const Value(this.value);

  final dynamic value;
}

final class ConflictValue extends EditorValue {
  const ConflictValue();
}

final class NoneValue extends EditorValue {
  const NoneValue();
}
