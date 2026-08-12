import "package:typewriter_panel/typewriter_panel.dart";

extension TypeDefinitionValidation on TypeDefinition {
  List<TypeDiagnostic> validateDeclaration() {
    final diagnostics = <TypeDiagnostic>[];
    final names = <String>{};
    for (final parameter in parameters) {
      if (!names.add(parameter.name)) {
        diagnostics.add(
          _declarationDiagnostic(
            "Type parameter '${parameter.name}' is duplicated",
          ),
        );
      }
    }
    final allowedParameters = parameters
        .map((parameter) => parameter.name)
        .toSet();
    for (final parameter in parameters) {
      diagnostics.addAll(
        parameter.bound.validateConstraints(allowedParameters),
      );
    }
    diagnostics
      ..addAll(parameters.validateBoundCycles())
      ..addAll(representation.validateConstraints(allowedParameters));
    for (final parent in parents) {
      for (final argument in parent.arguments) {
        diagnostics.addAll(argument.validateConstraints(allowedParameters));
      }
    }
    return [
      for (final diagnostic in diagnostics) diagnostic.copyWith(type: id),
    ];
  }
}

extension TypeParameterListValidation on List<TypeParameter> {
  List<TypeDiagnostic> validateBoundCycles() {
    final declared = map((parameter) => parameter.name).toSet();
    final dependencies = <String, Set<String>>{};
    for (final parameter in this) {
      dependencies
          .putIfAbsent(parameter.name, () => <String>{})
          .addAll(parameter.bound.parameterUses.intersection(declared));
    }
    final complete = <String>{};
    final active = <String>{};

    bool visit(String name) {
      if (complete.contains(name)) return false;
      if (!active.add(name)) return true;
      for (final dependency in dependencies[name] ?? const <String>{}) {
        if (visit(dependency)) return true;
      }
      active.remove(name);
      complete.add(name);
      return false;
    }

    for (final name in dependencies.keys) {
      if (visit(name)) {
        return [
          _declarationDiagnostic("Type parameter bounds contain recursion"),
        ];
      }
    }
    return const [];
  }
}

TypeDiagnostic _declarationDiagnostic(String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidConstraint,
  message: message,
);
