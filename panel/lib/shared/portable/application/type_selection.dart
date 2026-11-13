import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// A selection that chooses every argument of [use], the stored form of a
/// fully applied type.
skir.TypeSelection selectionOfUse(skir.NamedTypeUse use) => skir.TypeSelection(
  definition: use.definition,
  arguments: [
    for (final (index, argument) in use.arguments.indexed)
      skir.ChosenArgument(parameter: index, type: argument),
  ],
);

/// A selection of [definition] with no argument chosen yet.
skir.TypeSelection selectionOfDefinition(skir.TypeDefinitionId definition) =>
    skir.TypeSelection(definition: definition, arguments: const []);

/// Reads and edits of a stored selection. A selection stores only the
/// arguments a creator chose, keyed by parameter index and kept in parameter
/// order. Whether it is complete depends on the parameter count of its
/// definition, which the catalog answers.
extension TypeSelectionArguments on skir.TypeSelection {
  /// Whether this is the default instance, which names no definition. The
  /// panel uses it where it has no type to select, and it is never complete.
  bool get isUnknown => definition == skir.TypeDefinitionId.defaultInstance;

  /// The argument chosen for the parameter at [parameter], or null when that
  /// parameter is unfilled.
  skir.TypeUse? chosenAt(int parameter) => arguments.findByKey(parameter)?.type;

  /// This selection with [type] chosen for the parameter at [parameter].
  skir.TypeSelection withChosen(int parameter, skir.TypeUse type) =>
      skir.TypeSelection(
        definition: definition,
        arguments: [
          for (final argument in arguments)
            if (argument.parameter != parameter) argument,
          skir.ChosenArgument(parameter: parameter, type: type),
        ]..sort((a, b) => a.parameter.compareTo(b.parameter)),
      );

  /// This selection with the parameter at [parameter] unfilled.
  skir.TypeSelection withoutChosen(int parameter) => skir.TypeSelection(
    definition: definition,
    arguments: [
      for (final argument in arguments)
        if (argument.parameter != parameter) argument,
    ],
  );

  /// The fully applied type when every one of [parameterCount] parameters has
  /// a chosen argument, otherwise null (the selection is not complete).
  skir.NamedTypeUse? completeUse(int parameterCount) {
    if (isUnknown) return null;
    final chosen = <skir.TypeUse>[];
    for (var index = 0; index < parameterCount; index++) {
      final argument = chosenAt(index);
      if (argument == null) return null;
      chosen.add(argument);
    }
    return skir.NamedTypeUse(definition: definition, arguments: chosen);
  }
}
