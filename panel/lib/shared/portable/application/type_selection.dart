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
/// order. Whether it is complete depends on the parameters of its
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

  /// The parameters of this selection's definition as [declaration], its
  /// published declaration, lists them: none for a type a resource declares
  /// (content declarations take no parameters), and null when the definition
  /// is unknown.
  List<skir.TypeParameter>? parametersIn(skir.PublishedType? declaration) =>
      switch (declaration) {
        final declaration? => declaration.definition.parameters.toList(
          growable: false,
        ),
        null when definition.typeId is skir.TypeId_contentWrapper => const [],
        null => null,
      };

  /// Whether a creator has chosen everything this selection needs, read
  /// against [declaration]: an argument for every parameter that is not
  /// derived. A derived parameter never counts as missing, and a stored
  /// choice for one makes the selection invalid, as the realm refuses it.
  bool isFullyChosenIn(skir.PublishedType? declaration) =>
      switch (parametersIn(declaration)) {
        final parameters? => _choosesFor(parameters),
        null => false,
      };

  /// The fully applied type the creator's choices make, read against
  /// [declaration], or null while one is missing. A definition with a derived
  /// parameter has no such type here: its derived argument comes from the
  /// resource that holds the selection, so only that resource's bound type is
  /// complete.
  skir.NamedTypeUse? completeUseIn(skir.PublishedType? declaration) {
    final parameters = parametersIn(declaration);
    if (parameters == null ||
        parameters.any((parameter) => parameter.derived) ||
        !_choosesFor(parameters)) {
      return null;
    }
    return skir.NamedTypeUse(
      definition: definition,
      arguments: [
        for (var index = 0; index < parameters.length; index++)
          chosenAt(index)!,
      ],
    );
  }

  /// Whether this selection chooses exactly what a creator chooses for
  /// [parameters]: an argument for every parameter that is not derived, and
  /// none for a derived parameter or for a position [parameters] does not
  /// have.
  bool _choosesFor(List<skir.TypeParameter> parameters) {
    if (isUnknown) return false;
    for (final argument in arguments) {
      final position = argument.parameter;
      if (position < 0 ||
          position >= parameters.length ||
          parameters[position].derived) {
        return false;
      }
    }
    for (final (index, parameter) in parameters.indexed) {
      if (!parameter.derived && chosenAt(index) == null) return false;
    }
    return true;
  }
}
