/// Reads structural function types.
///
/// A function type names its context slots and parameters; names are part of
/// the type, so two function types agree only when their names and part types
/// agree. A value of a function type is stored as the Formula record. The
/// Kotlin counterpart is the function helpers in `TypeModel.kt` in
/// typewriter-contracts.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The record every function type stores its values as: the body's source and
/// the references inside it. Its id is `FORMULA_TYPE_ID` in typewriter-contracts.
final formulaUse = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "a2ac548560b44c90a92d929a273eacc5",
    ),
    revision: 1,
  ),
  arguments: const [],
);

extension TypeUseStoredForm on skir.TypeUse {
  /// The use a value at this position is stored as: a function type stores
  /// its body as a Formula record, every other use stores itself.
  skir.TypeUse get storedUse => this is skir.TypeUse_functionWrapper
      ? skir.TypeUse.wrapNamed(formulaUse)
      : this;
}

extension FunctionTypeUseParts on skir.FunctionTypeUse {
  /// Every type this function mentions: context, then parameters, then result.
  List<skir.TypeUse> get parts => [
    for (final slot in context) slot.type,
    for (final slot in parameters) slot.type,
    result,
  ];
}

extension FunctionTypeTemplateParts on skir.FunctionTypeTemplate {
  /// Every type this template mentions: context, then parameters, then result.
  List<skir.TypeTemplate> get parts => [
    for (final slot in context) slot.type,
    for (final slot in parameters) slot.type,
    result,
  ];

  /// Whether [use] has the same context and parameter names, in order.
  bool sameSlots(skir.FunctionTypeUse use) =>
      _sameNames(
        context.map((slot) => slot.name),
        use.context.map((slot) => slot.name),
      ) &&
      _sameNames(
        parameters.map((slot) => slot.name),
        use.parameters.map((slot) => slot.name),
      );

  /// The function use of this template with each part converted by
  /// [convert], or null when any part converts to null.
  skir.TypeUse? toUse(skir.TypeUse? Function(skir.TypeTemplate) convert) {
    skir.FunctionParameterUse? slot(skir.FunctionParameterTemplate template) =>
        switch (convert(template.type)) {
          final type? => skir.FunctionParameterUse(
            name: template.name,
            type: type,
          ),
          null => null,
        };
    final context = [for (final template in this.context) slot(template)];
    final parameters = [for (final template in this.parameters) slot(template)];
    final result = convert(this.result);
    if (result == null || context.contains(null) || parameters.contains(null)) {
      return null;
    }
    return skir.TypeUse.createFunction(
      context: context.nonNulls,
      parameters: parameters.nonNulls,
      result: result,
    );
  }
}

bool _sameNames(Iterable<String> left, Iterable<String> right) {
  final a = left.toList();
  final b = right.toList();
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
