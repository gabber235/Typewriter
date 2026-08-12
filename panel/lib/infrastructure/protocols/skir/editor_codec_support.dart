import "package:typewriter_panel/typewriter_panel.dart";

extension TypeResultMapping<T> on TypeResult<T> {
  TypeResult<R> mapValue<R>(R Function(T value) transform) => switch (this) {
    TypeSuccess(:final value) => TypeResult.success(transform(value)),
    TypeFailure(:final diagnostics) => TypeResult.failure(diagnostics),
  };
}

TypeDiagnostic wireDiagnostic(String message) =>
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message);

TypeResult<T> invalidWire<T>(String message) =>
    TypeResult.failure([wireDiagnostic(message)]);

TypeResult<R> combineResults<A, B, R>(
  TypeResult<A> first,
  TypeResult<B> second,
  R Function(A first, B second) combine,
) {
  final diagnostics = [...first.diagnostics, ...second.diagnostics];
  if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
  return TypeResult.success(
    combine(first.valueOrNull as A, second.valueOrNull as B),
  );
}
