import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "type_id.freezed.dart";

@freezed
sealed class TypeId with _$TypeId {
  const TypeId._();

  const factory TypeId.option() = OptionTypeId;

  const factory TypeId.some() = SomeTypeId;

  const factory TypeId.none() = NoneTypeId;

  @Assert("namespace != \"\"", "Namespace must not be empty.")
  @Assert("name != \"\"", "Name must not be empty.")
  const factory TypeId.qualified({
    required String namespace,
    required String name,
  }) = QualifiedTypeId;

  String get displayName => switch (this) {
    OptionTypeId() => "Option",
    SomeTypeId() => "Some",
    NoneTypeId() => "None",
    QualifiedTypeId(:final namespace, :final name) => "$namespace::$name",
  };

  @override
  String toString() => switch (this) {
    OptionTypeId() || SomeTypeId() || NoneTypeId() => "builtin::$displayName",
    QualifiedTypeId() => displayName,
  };
}

@freezed
abstract class ResolvedTypeRef with _$ResolvedTypeRef {
  @Assert("revision > 0", "Revision must be positive.")
  const factory ResolvedTypeRef({
    required TypeId id,
    required int revision,
    @Default([]) List<TypeExpression> arguments,
  }) = _ResolvedTypeRef;

  const ResolvedTypeRef._();

  ResolvedTypeRef withArguments(Iterable<TypeExpression> values) =>
      ResolvedTypeRef(id: id, revision: revision, arguments: values.toList());

  @override
  String toString() {
    final base = "$id@$revision";
    if (arguments.isEmpty) return base;
    return "$base<${arguments.join(", ")}>";
  }
}
