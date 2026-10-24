import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_expression.freezed.dart";
part "portable_expression_queries.dart";
part "canonical_read_models.dart";

/// The outcome of one evaluation, with the authored locations it read.
///
/// Missing data stays distinct from a failure, so presentation can choose a
/// fallback without hiding a broken expression.
@freezed
sealed class PortableExpressionResult with _$PortableExpressionResult {
  const factory PortableExpressionResult.available(
    skir.DataValue value,

    /// Distinct authored locations whose stored values decided this result,
    /// in first read order. Save conflict witnesses are built from exactly
    /// these: input projections of located bindings and the resources panel
    /// operations read. Lambda locals are never reads.
    List<skir.ValueLocation> reads,
  ) = PortableExpressionAvailable;

  const factory PortableExpressionResult.unavailable(
    /// Authored locations whose missing values block the result. Empty when
    /// the missing data has no authored location.
    List<skir.ValueLocation> locations,
    List<skir.ValueLocation> reads,
  ) = PortableExpressionUnavailable;

  const factory PortableExpressionResult.failed(
    /// The declared failure, from operations.yaml.
    skir.FailureId failure,
    String message, {

    /// The reads so far plus the located lambda locals in scope, as Kotlin
    /// reports them.
    required List<skir.ValueLocation> locations,
    required List<skir.ValueLocation> reads,
  }) = PortableExpressionFailed;
}

/// A value bound for evaluation. A [location] makes reads through the binding
/// authored reads; [schema] is the binding's declared type, when known.
final class PortableExpressionBinding {
  const PortableExpressionBinding({
    required this.value,
    this.location,
    this.schema,
  });

  final skir.DataValue value;
  final skir.ValueLocation? location;
  final PortablePresentationBindingSchema? schema;
}

/// Evaluates portable expression trees against bindings, with the generated
/// call rule dispatching every operation to [panelKernel].
///
/// The evaluator owns the structural forms (literals, input and local
/// projections, field projection, short circuit, conditionals and fallbacks)
/// and the uniform call rule; operations themselves are pure kernels. Each
/// [evaluate] call resets its step, collection item and read tracking.
/// Materials are checked by Realm when it builds them, so the panel trusts
/// the trees it receives: an ill typed tree fails with `ill_typed_argument`
/// instead of crashing.
final class PortableExpressionEvaluator {
  PortableExpressionEvaluator(
    Map<skir.ExpressionBindingId, skir.DataValue> bindings, {
    required this.budget,
    CheckedEditorCatalog? catalog,
    this.queries,
    this.subject,
  }) : catalog = catalog ?? queries?.catalog,
       _bindings = Map.unmodifiable({
         for (final entry in bindings.entries)
           entry.key: PortableExpressionBinding(value: entry.value),
       });

  PortableExpressionEvaluator.located(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, {
    required this.budget,
    CheckedEditorCatalog? catalog,
    this.queries,
    this.subject,
  }) : catalog = catalog ?? queries?.catalog,
       _bindings = Map.unmodifiable(bindings);

  /// An evaluator over a configured value bound at its authored [location],
  /// as Realm evaluates rules: with the type facts of [catalog].
  factory PortableExpressionEvaluator.configuredValue({
    required skir.DataValue value,
    required skir.ValueLocation location,
    required skir.EvaluationBudget budget,
    required CheckedEditorCatalog catalog,
  }) => PortableExpressionEvaluator.located(
    {
      configuredValueBindingId: PortableExpressionBinding(
        value: value,
        location: location,
      ),
    },
    budget: budget,
    catalog: catalog,
  );

  final skir.EvaluationBudget budget;

  /// The catalog whose type facts typed operations use; without one, those
  /// operations fail `outside_rule_profile`.
  final CheckedEditorCatalog? catalog;

  /// The authoring observation resource operations read.
  final PortableExpressionQueries? queries;

  /// The selection of the material subject whose type parameters call type
  /// arguments may name. Without it, type arguments must be closed.
  final skir.TypeSelection? subject;

  final Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
  final _frames = <List<_Local>>[];
  // Insertion ordered: a repeated read keeps its first position.
  final _reads = <skir.ValueLocation>{};
  var _steps = 0;
  var _collectionItems = 0;
  var _depth = 0;

  PortableExpressionResult evaluate(skir.ExpressionNode node) {
    _reads.clear();
    _frames.clear();
    _steps = 0;
    _collectionItems = 0;
    _depth = 0;
    final result = _evaluate(node);
    final reads = List<skir.ValueLocation>.unmodifiable(_reads);
    return switch (result) {
      _Available(:final value) => PortableExpressionAvailable(value, reads),
      _Unavailable(:final locations) => PortableExpressionUnavailable(
        List.unmodifiable(locations),
        reads,
      ),
      _Failed(:final failure, :final message, :final locations) =>
        PortableExpressionFailed(
          failure,
          message,
          locations: List.unmodifiable(locations),
          reads: reads,
        ),
    };
  }

  _Evaluation _evaluate(skir.ExpressionNode node) {
    _depth++;
    try {
      if (_depth > portableValueDepthLimit) {
        _fail(skir.PortableFailures.expressionDepthLimit);
      }
      _consumeSteps(1);
      final projection = _projection(node);
      if (projection != null) return _project(projection);
      return switch (node) {
        skir.ExpressionNode_literalWrapper(:final value) => _Available(
          admitPortableValue(
            value,
            skir.PortableFailures.invalidExpressionLiteral,
          ),
        ),
        skir.ExpressionNode_fieldWrapper(:final value) => _field(value),
        skir.ExpressionNode_andWrapper(:final value) => _logical(
          value,
          conjunction: true,
        ),
        skir.ExpressionNode_orWrapper(:final value) => _logical(
          value,
          conjunction: false,
        ),
        skir.ExpressionNode_conditionalWrapper(:final value) => _conditional(
          value,
        ),
        skir.ExpressionNode_orElseWrapper(:final value) => _orElse(value),
        skir.ExpressionNode_callWrapper(:final value) => _call(value),
        skir.ExpressionNode_lambdaWrapper() => _fail(
          skir.PortableFailures.illTypedArgument,
          "A lambda is only an argument of a lambda parameter.",
        ),
        _ => _fail(skir.PortableFailures.unknownExpression),
      };
    } on skir.PortableOperationFailure catch (failure) {
      return _Failed(failure.failure, failure.message, _failureLocations());
    } finally {
      _depth--;
    }
  }

  /// The input or local a chain of field nodes projects, with the joined path
  /// and the number of field nodes, so only the deepest path is read.
  _Projection? _projection(skir.ExpressionNode node) {
    var current = node;
    final suffixes = <Iterable<skir.PathSegment>>[];
    while (current is skir.ExpressionNode_fieldWrapper) {
      suffixes.add(current.value.path.segments);
      current = current.value.source;
      if (_depth + suffixes.length > portableValueDepthLimit) {
        _fail(skir.PortableFailures.expressionDepthLimit);
      }
    }
    final suffix = [for (final segments in suffixes.reversed) ...segments];
    return switch (current) {
      skir.ExpressionNode_inputWrapper(:final value) => _Projection(
        input: value,
        path: [...value.path.segments, ...suffix],
        descents: suffixes.length,
      ),
      skir.ExpressionNode_localWrapper(:final value) => _Projection(
        local: value,
        path: [...value.path.segments, ...suffix],
        descents: suffixes.length,
      ),
      _ => null,
    };
  }

  _Evaluation _project(_Projection projection) {
    _consumeSteps(projection.descents);
    final input = projection.input;
    if (input != null) {
      final binding =
          _bindings[input.binding] ??
          _fail(
            skir.PortableFailures.unknownExpressionBinding,
            "Unknown expression binding ${input.binding.value}.",
          );
      final location = _below(binding.location, projection.path);
      if (location != null) _reads.add(location);
      return _readValue(binding.value, projection.path, location);
    }
    // A local holds a value an input read or a literal produced; reading it
    // is never a new dependency.
    final local = _local(projection.local!);
    return _readValue(
      local.value,
      projection.path,
      local.locationOf(projection.path),
    );
  }

  _Evaluation _readValue(
    skir.DataValue value,
    List<skir.PathSegment> path,
    skir.ValueLocation? location,
  ) => switch (value.readExpressionAt(skir.ValuePath(segments: path))) {
    PortablePathValue(:final value) when value != skir.DataValue.unfilled =>
      _Available(value),
    _ => _Unavailable([?location]),
  };

  _Local _local(skir.ExpressionLocal reference) {
    final frameIndex = _frames.length - 1 - reference.depth;
    if (reference.depth < 0 ||
        reference.slot < 0 ||
        frameIndex < 0 ||
        reference.slot >= _frames[frameIndex].length) {
      _fail(skir.PortableFailures.invalidExpressionLocal);
    }
    return _frames[frameIndex][reference.slot];
  }

  /// Projects a path from a computed value. Its source has no authored
  /// location, so missing data here has none either.
  _Evaluation _field(skir.FieldExpression expression) {
    final source = _evaluate(expression.source);
    if (source is! _Available) return source;
    final value = source.value;
    if (value == skir.DataValue.unfilled ||
        value.authoredPayload == skir.DataValue.null_) {
      return const _Unavailable([]);
    }
    return _readValue(value, expression.path.segments.toList(), null);
  }

  _Evaluation _logical(
    skir.LogicalExpression expression, {
    required bool conjunction,
  }) {
    final left = _evaluate(expression.left);
    if (left is! _Available) return left;
    final decided = _condition(left.value);
    if (decided != conjunction) return _Available(skir.booleanValue(decided));
    final right = _evaluate(expression.right);
    if (right is! _Available) return right;
    return _Available(skir.booleanValue(_condition(right.value)));
  }

  _Evaluation _conditional(skir.ConditionalExpression expression) {
    final test = _evaluate(expression.test);
    if (test is! _Available) return test;
    return _evaluate(
      _condition(test.value) ? expression.then : expression.otherwise,
    );
  }

  bool _condition(skir.DataValue value) => switch (value.authoredPayload) {
    skir.DataValue_booleanWrapper(:final value) => value,
    _ => _fail(skir.PortableFailures.expressionResultNotBoolean),
  };

  _Evaluation _orElse(skir.FallbackExpression expression) {
    final value = _evaluate(expression.value);
    return switch (value) {
      _Available(:final value)
          when value != skir.DataValue.null_ &&
              value != skir.DataValue.unfilled =>
        _Available(value),
      _Failed() => value,
      _ => _evaluate(expression.fallback),
    };
  }

  /// The uniform call rule: everything operation specific comes from the
  /// generated declaration and dispatch.
  _Evaluation _call(skir.CallExpression call) {
    final id = call.operation.value;
    final declaration =
        skir.portableOperation(id) ??
        _fail(skir.PortableFailures.unknownOperation, "Unknown operation $id.");
    if (!declaration.accepts(call.arguments.length)) {
      _fail(
        skir.PortableFailures.invalidArgumentCount,
        "$id takes ${declaration.parameters.length} arguments, not "
        "${call.arguments.length}.",
      );
    }
    if (call.typeArguments.length != declaration.typeArguments) {
      _fail(
        skir.PortableFailures.illTypedArgument,
        "$id takes ${declaration.typeArguments} type arguments.",
      );
    }
    final typeArguments = [
      for (final template in call.typeArguments) _closeType(template),
    ];
    final arguments = <skir.KernelArgument>[];
    final missing = <skir.ValueLocation>{};
    var incomplete = false;
    for (final (index, argument) in call.arguments.indexed) {
      final kind = declaration.parameterAt(index)!;
      switch (kind) {
        case skir.PortableParameterKind.value ||
            skir.PortableParameterKind.partial ||
            skir.PortableParameterKind.located:
          final result = _evaluate(argument);
          if (result is! _Available) return result;
          final location = _sourceLocation(argument);
          if (kind == skir.PortableParameterKind.value) {
            final unfilled = unfilledPaths(result.value);
            if (unfilled.isNotEmpty) {
              incomplete = true;
              if (location != null) {
                missing.addAll([
                  for (final path in unfilled) _below(location, path)!,
                ]);
              }
            }
          }
          arguments.add(skir.KernelValue(result.value, location));
        case skir.PortableParameterKind.each:
          final each = _each(arguments.first, _lambda(argument, arity: 1));
          if (each is! _EachResults) return each as _Evaluation;
          arguments.add(skir.KernelEach(each.results));
        case skir.PortableParameterKind.step ||
            skir.PortableParameterKind.comparator:
          arguments.add(
            _kernelLambda(arguments.first, _lambda(argument, arity: 2)),
          );
        case skir.PortableParameterKind.apply:
          arguments.add(_kernelLambda(null, _lambda(argument, arity: 1)));
      }
    }
    if (incomplete) return _Unavailable(missing.toList());
    try {
      final result = skir.invokePortableOperation(
        panelKernel,
        id,
        arguments,
        typeArguments,
        skir.KernelContext(
          meter: _EvaluationMeter(this),
          typeFacts: switch (catalog) {
            final catalog? => _CatalogTypes(catalog),
            null => null,
          },
          resourceAccess: queries == null ? null : _EvaluationResources(this),
        ),
      )!;
      return switch (result) {
        skir.PortableMaybeValue(:final value) => _Available(
          _chargeResult(value),
        ),
        skir.PortableMaybeMissing(:final locations) => _Unavailable(locations),
      };
    } on _LambdaInterrupted catch (interrupted) {
      return interrupted.result;
    }
  }

  /// Charges the size of an available call result as collection items: one
  /// per item of a list or set and per top level row of a map, and one per
  /// started 64 UTF-16 code units of text or 64 bytes. Results that grow
  /// without collections, such as a fold doubling a text, stay bounded.
  skir.DataValue _chargeResult(skir.DataValue value) {
    _consumeItems(switch (value) {
      skir.DataValue_listValueWrapper(value: final list) => list.items.length,
      skir.DataValue_setValueWrapper(value: final set) => set.items.length,
      skir.DataValue_mapValueWrapper(value: final map) => map.rows.length,
      skir.DataValue_stringValueWrapper(value: final text) => _chunks(
        text.length,
      ),
      skir.DataValue_bytesWrapper(value: final bytes) => _chunks(bytes.length),
      _ => 0,
    });
    return value;
  }

  /// Runs an each lambda for every item of [source], in item order, before
  /// the kernel. A missing item body makes the call missing after every item
  /// ran; a failed one returns at once.
  Object _each(skir.KernelArgument source, skir.ExpressionNode body) {
    final value = source as skir.KernelValue;
    final entries = _isMap(value.value);
    final results = <skir.DataValue>[];
    final missing = <skir.ValueLocation>{};
    var incomplete = false;
    for (final item in value.value.asItems()) {
      _consumeItems(1);
      final location = _below(value.location, [
        skir.PathSegment.createItem(id: item.id),
      ]);
      final result = _inFrame([
        _Local(item.value, location, entry: entries),
      ], body);
      switch (result) {
        case _Available(:final value):
          results.add(value);
        case _Unavailable(:final locations):
          incomplete = true;
          missing.addAll(locations.isEmpty ? [?location] : locations);
        case _Failed():
          return result;
      }
    }
    if (incomplete) return _Unavailable(missing.toList());
    return _EachResults(results);
  }

  /// A lambda the kernel drives. A local with an item id is an item of
  /// [source], so it keeps that item's location.
  skir.KernelLambda _kernelLambda(
    skir.KernelArgument? source,
    skir.ExpressionNode body,
  ) {
    final (origin, entries) = switch (source) {
      skir.KernelValue(:final value, :final location) => (
        location,
        _isMap(value),
      ),
      _ => (null, false),
    };
    return skir.KernelLambda((locals) {
      final result = _inFrame([
        for (final local in locals)
          switch (local.item) {
            final item? => _Local(
              local.value,
              _below(origin, [skir.PathSegment.createItem(id: item)]),
              entry: entries,
            ),
            null => _Local(local.value, null),
          },
      ], body);
      return switch (result) {
        _Available(:final value) => value,
        _ => throw _LambdaInterrupted(result),
      };
    });
  }

  skir.ExpressionNode _lambda(
    skir.ExpressionNode argument, {
    required int arity,
  }) => switch (argument) {
    skir.ExpressionNode_lambdaWrapper(:final value) when value.arity == arity =>
      value.body,
    _ => _fail(
      skir.PortableFailures.illTypedArgument,
      "Expected a lambda of $arity parameters.",
    ),
  };

  _Evaluation _inFrame(List<_Local> locals, skir.ExpressionNode body) {
    _frames.add(List.unmodifiable(locals));
    try {
      return _evaluate(body);
    } finally {
      _frames.removeLast();
    }
  }

  /// The authored location of an argument that projects a located input or
  /// local; computed arguments have none.
  skir.ValueLocation? _sourceLocation(skir.ExpressionNode argument) {
    final projection = _projection(argument);
    if (projection == null) return null;
    final input = projection.input;
    return input != null
        ? _below(_bindings[input.binding]?.location, projection.path)
        : _local(projection.local!).locationOf(projection.path);
  }

  skir.TypeUse _closeType(skir.TypeTemplate template) {
    final subject = this.subject;
    final catalog = this.catalog;
    final closed =
        _closedUse(template) ??
        (subject != null && catalog != null
            ? catalog.applyTemplate(template, subject)
            : null);
    return closed ??
        _fail(
          skir.PortableFailures.illTypedArgument,
          "A type argument names a type parameter this evaluation cannot "
          "close.",
        );
  }

  List<skir.ValueLocation> _failureLocations() => {
    ..._reads,
    for (final frame in _frames)
      for (final local in frame) ?local.location,
  }.toList();

  void _consumeSteps(int count) {
    _steps += count;
    if (_steps > budget.maxSteps) {
      _fail(skir.PortableFailures.expressionStepLimit);
    }
  }

  void _consumeItems(int count) {
    _collectionItems += count;
    if (_collectionItems > budget.maxCollectionItems) {
      _fail(skir.PortableFailures.expressionCollectionLimit);
    }
  }
}

/// The started chunks of 64 units in [length]: ceil(length / 64).
int _chunks(int length) => (length + 63) ~/ 64;

Never _fail(skir.FailureId failure, [String? message]) =>
    throw skir.PortableOperationFailure(failure, message);

/// A lambda local: an item, entry or accumulator value and, for an item of
/// a located source, the item's location. A map entry is located at its
/// row, so its `key` and `value` fields are the row's key and value.
final class _Local {
  const _Local(this.value, this.location, {this.entry = false});

  final skir.DataValue value;
  final skir.ValueLocation? location;
  final bool entry;

  /// The location of [path] below this local.
  skir.ValueLocation? locationOf(List<skir.PathSegment> path) {
    if (entry && path.isNotEmpty) {
      final row = switch (path.first) {
        skir.PathSegment_fieldWrapper(value: final field)
            when field.name == "key" =>
          skir.PathSegment.mapKey,
        skir.PathSegment_fieldWrapper(value: final field)
            when field.name == "value" =>
          skir.PathSegment.mapValue,
        _ => null,
      };
      if (row != null) return _below(location, [row, ...path.skip(1)]);
    }
    return _below(location, path);
  }
}

bool _isMap(skir.DataValue value) =>
    value.authoredPayload is skir.DataValue_mapValueWrapper;

final class _Projection {
  const _Projection({
    required this.path,
    required this.descents,
    this.input,
    this.local,
  });

  final skir.ExpressionInput? input;
  final skir.ExpressionLocal? local;
  final List<skir.PathSegment> path;

  /// The field nodes above the root, each of which costs a step.
  final int descents;
}

sealed class _Evaluation {
  const _Evaluation();
}

final class _Available extends _Evaluation {
  const _Available(this.value);

  final skir.DataValue value;
}

final class _Unavailable extends _Evaluation {
  const _Unavailable(this.locations);

  final List<skir.ValueLocation> locations;
}

final class _Failed extends _Evaluation {
  const _Failed(this.failure, this.message, this.locations);

  final skir.FailureId failure;
  final String message;
  final List<skir.ValueLocation> locations;
}

final class _EachResults {
  const _EachResults(this.results);

  final List<skir.DataValue> results;
}

/// Aborts a kernel driven lambda whose body is missing or failed; the call
/// rule returns [result] for the whole call.
final class _LambdaInterrupted implements Exception {
  const _LambdaInterrupted(this.result);

  final _Evaluation result;
}

final class _EvaluationMeter implements skir.PortableMeter {
  const _EvaluationMeter(this._evaluator);

  final PortableExpressionEvaluator _evaluator;

  @override
  void items(int count) => _evaluator._consumeItems(count);

  @override
  void steps(int count) => _evaluator._consumeSteps(count);
}

/// The catalog's type facts for typed operations.
final class _CatalogTypes implements skir.PortableTypes {
  const _CatalogTypes(this._catalog);

  final CheckedEditorCatalog _catalog;

  @override
  bool admits(skir.DataValue value, skir.TypeUse type) =>
      _catalog.admitsPortableValue(type, value);

  @override
  List<String> enumCases(skir.TypeUse type) {
    final representation = switch (type) {
      skir.TypeUse_namedWrapper(:final value) =>
        _catalog.published(value.definition)?.definition.representation,
      _ => null,
    };
    return switch (representation) {
      skir.RepresentationTemplate_enumerationWrapper(:final value) => [
        for (final variant in value.cases) variant.key,
      ],
      _ => const [],
    };
  }

  @override
  bool isInstance(skir.DataValue value, skir.TypeUse type) => switch (value) {
    skir.DataValue_namedWrapper(:final value) => _catalog.isReadableAs(
      skir.TypeUse.wrapNamed(value.actualType),
      type,
    ),
    _ when value == skir.DataValue.null_ =>
      type is skir.TypeUse_nullableWrapper,
    _ => _catalog.admitsPortableValue(type, value),
  };
}

/// Authored resource access through the evaluation's observation. Every
/// resource a kernel reads is recorded at its root.
final class _EvaluationResources implements skir.PortableResources {
  const _EvaluationResources(this._evaluator);

  final PortableExpressionEvaluator _evaluator;

  CheckedEditorCatalog? get _catalog => _evaluator.catalog;

  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) {
    _evaluator._reads.add(
      skir.ValueLocation(resource: id, path: editorRootPath),
    );
    return _evaluator.queries?.authored?.resource(id);
  }

  @override
  bool selects(skir.TypeSelection configuration, skir.TypeUse type) =>
      switch (_catalog) {
        final catalog? => _selectionMatches(catalog, configuration, type),
        null => false,
      };

  @override
  bool linkTargets(skir.LinkValue link, skir.TypeSelection configuration) {
    final catalog = _catalog;
    if (catalog == null) return false;
    final relation = catalog.snapshot.relations
        .where(
          (candidate) =>
              candidate.first.id == link.endpoint ||
              candidate.second.id == link.endpoint,
        )
        .singleOrNull;
    // Without a published relation there is no family to check the target
    // against, so only the resource's existence guards the link.
    if (relation == null) return true;
    // The link sits on its own endpoint; it targets the opposite one.
    final opposite = relation.first.id == link.endpoint
        ? relation.second
        : relation.first;
    return catalog
        .nominalDefinitions(configuration)
        .contains(opposite.resource.definition);
  }

  @override
  skir.PublishedType? declaration(skir.TypeDefinitionId definition) =>
      _catalog?.published(definition);
}

/// Whether a resource configured as [selection] is a value of [expected]. A
/// pending selection matches its nominal family when its chosen arguments are
/// readable as the expected ones.
bool _selectionMatches(
  CheckedEditorCatalog catalog,
  skir.TypeSelection selection,
  skir.TypeUse expected,
) {
  if (selection is skir.TypeSelection_completeWrapper) {
    return catalog.selectionMatches(selection, expected);
  }
  final named = catalog.namedUse(expected);
  if (named == null ||
      !catalog.nominalDefinitions(selection).contains(named.definition)) {
    return false;
  }
  if (selection case skir.TypeSelection_pendingWrapper(:final value)
      when value.definition == named.definition) {
    if (value.arguments.length != named.arguments.length) return false;
    for (final (index, argument) in value.arguments.indexed) {
      if (argument case skir.ArgumentSelection_chosenWrapper(:final value)) {
        if (!catalog.isReadableAs(value, named.arguments.elementAt(index))) {
          return false;
        }
      }
    }
  }
  return true;
}

/// The template as a closed type use, or null when it names a parameter.
skir.TypeUse? _closedUse(skir.TypeTemplate template) => switch (template) {
  skir.TypeTemplate_namedWrapper(:final value) => () {
    final arguments = [
      for (final argument in value.arguments) _closedUse(argument),
    ];
    return arguments.contains(null)
        ? null
        : skir.TypeUse.createNamed(
            definition: value.definition,
            arguments: arguments.nonNulls,
          );
  }(),
  skir.TypeTemplate_nullableWrapper(:final value) => switch (_closedUse(
    value.value,
  )) {
    final use? => skir.TypeUse.createNullable(value: use),
    null => null,
  },
  skir.TypeTemplate_scalarWrapper(:final value) => skir.TypeUse.wrapScalar(
    value,
  ),
  _ => null,
};

skir.ValueLocation? _below(
  skir.ValueLocation? location,
  Iterable<skir.PathSegment> path,
) => location == null
    ? null
    : skir.ValueLocation(
        resource: location.resource,
        path: skir.ValuePath(segments: [...location.path.segments, ...path]),
      );

/// A call node of the declared operation [operation], for panel built trees.
/// The panel has no shortcuts: it composes primitives directly.
skir.ExpressionNode portableCall(
  String operation,
  List<skir.ExpressionNode> arguments, {
  List<skir.TypeTemplate> typeArguments = const [],
}) => skir.ExpressionNode.createCall(
  operation: skir.OperationId(value: operation),
  typeArguments: typeArguments,
  arguments: arguments,
);
