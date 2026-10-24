part of "resource_creation.dart";

/// Owns pending values and choices until one synchronous workspace admission.
/// Reference pickers see a private graph containing unfinished dependencies.
/// Question checkpoints restore that graph when stepping back, so abandoned
/// answers cannot leak resources or inverse links into the admitted edit.
final class _ResourceCreationOperation {
  _ResourceCreationOperation({
    required this.base,
    required this.commands,
    required this.context,
    required this.isCurrent,
  });

  final AuthoringDocument base;
  final AuthoredResourceCommands commands;
  final BuildContext context;
  final bool Function() isCurrent;
  final Map<skir.ResourceId, _PendingCreation> _nodes = {};
  final List<ResolvedReference> _references = [];
  final Map<skir.ValueLocation, ReferenceMaterialization> _embedded = {};
  final Map<skir.ValueLocation, skir.DataValue> _values = {};
  CheckedEditorCatalog get catalog => base.catalog;

  bool _cancelled = false;
  final _questions = <_CreationQuestion>[];
  final _cancelledSignal = Completer<void>();

  void cancel() {
    _cancelled = true;
    if (!_cancelledSignal.isCompleted) _cancelledSignal.complete();
  }

  void _checkCurrent() {
    if (_cancelled || !isCurrent()) throw const _CreationCancelled();
  }

  Future<skir.ResourceId> resolve(
    ResourceCreationRequest original,
    CreationContext creationContext,
  ) async {
    var request = original;
    _checkCurrent();
    if (base.resource(request.id) != null || _nodes.containsKey(request.id)) {
      throw StateError("The resource identity is already in use");
    }
    if (catalog.isAbstractRecordSelection(request.configuration)) {
      final chosen = await _chooseConcreteType(request.configuration);
      _checkCurrent();
      if (chosen == null) throw const _CreationCancelled();
      request = request.copyWith(configuration: chosen);
    }
    if (request.configuration is! skir.TypeSelection_completeWrapper ||
        !catalog
            .nominalDefinitions(request.configuration)
            .contains(request.type) ||
        !catalog.creatableTypes.contains(request.configuration.definition) ||
        catalog.isAbstractRecordSelection(request.configuration)) {
      throw StateError("The selected resource needs a concrete available type");
    }
    final initialization = skir.ValuePreparationRequest(
      catalog: base.generation,
      target: skir.PreparationTarget.wrapRecord(request.configuration),
      suppliedValue: skir.DataValue.createRecord(fields: request.supplied),
    );
    final at = skir.ValueLocation(resource: request.id, path: editorRootPath);
    await _prepare(
      initialization,
      at,
      creationContext,
      publish: (step) => _nodes[request.id] = _PendingCreation(
        request: request,
        context: creationContext,
        step: step,
      ),
    );
    return request.id;
  }

  Future<skir.PreparedValue> _prepare(
    skir.ValuePreparationRequest request,
    skir.ValueLocation at,
    CreationContext creationContext, {
    required void Function(skir.PrepareValueResult) publish,
  }) async {
    var step = await commands.prepareStep(
      skir.PreparationOperation.wrapStart(request),
    );
    final answered = <_CreationQuestion>[];
    _CreationQuestion? retry;
    while (true) {
      _checkCurrent();
      publish(step);
      switch (step) {
        case skir.PrepareValueResult_readyWrapper(:final value):
          try {
            await _resolveDefaults(
              value.recordContent,
              at,
              creationContext,
              previous:
                  answered.lastOrNull ??
                  _questions.where((question) => question.presented).lastOrNull,
            );
            return value;
          } on _CreationBack catch (back) {
            final index = answered.indexOf(back.target);
            if (index < 0) rethrow;
            back.target.restore();
            step = back.target.step;
            retry = back.target;
            answered.removeRange(index, answered.length);
          }
        case skir.PrepareValueResult_unavailableErrorWrapper(:final value):
          throw StateError(
            value.findings.map((finding) => finding.message).join("\n"),
          );
        case skir.PrepareValueResult_catalogChangedErrorWrapper(:final value):
          throw CatalogGenerationChanged(value);
        case skir.PrepareValueResult_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.PrepareValueResult_unknown():
          throw StateError("Realm returned an unknown preparation outcome");
        case skir.PrepareValueResult_needsInputWrapper(:final value):
          final input = value.requiredInputs.firstOrNull;
          if (input == null) {
            throw StateError("Preparation cannot make progress");
          }
          final question =
              retry ??
              _checkpoint(
                step,
                answered.lastOrNull ??
                    _questions
                        .where((question) => question.presented)
                        .lastOrNull,
              );
          retry = null;
          _questions.add(question);
          try {
            final location = skir.ValueLocation(
              resource: at.resource,
              path: skir.ValuePath(
                segments: [...at.path.segments, ...input.path.segments],
              ),
            );
            final answer = await _answer(input, location, creationContext);
            _checkCurrent();
            step = await commands.prepareStep(
              skir.PreparationOperation.createResume(
                draft: value,
                answers: [skir.InputAnswer(path: input.path, value: answer)],
              ),
            );
            if (question.presented) answered.add(question);
          } on _CreationBack catch (back) {
            final index = answered.indexOf(back.target);
            if (!identical(back.target, question) && index < 0) rethrow;
            back.target.restore();
            step = back.target.step;
            retry = back.target;
            if (index >= 0) answered.removeRange(index, answered.length);
          } finally {
            _questions.removeLast();
          }
      }
    }
  }

  Future<skir.DataValue> _answer(
    skir.RequiredInput input,
    skir.ValueLocation location,
    CreationContext creationContext,
  ) async {
    final view = _view();
    final record = view.resource(location.resource)!;
    if (catalog.referenceTypeAt(record, location.path) != null) {
      final reference = await _chooseReference(location, creationContext);
      _remember(reference);
      final named = catalog.namedUse(input.expected);
      if (named == null) {
        throw StateError("The reference value type is unavailable");
      }
      final connection = reference.connection;
      final opposite = switch (connection.counterpart) {
        skir.CounterpartChoice_existingWrapper(:final value) =>
          value.id.location.path,
        null => null,
        _ => throw StateError(
          "The reference counterpart has no exact location",
        ),
      };
      return skir.DataValue.createNamed(
        actualType: named,
        payload: skir.DataValue.createLink(
          endpoint: connection.source.id.endpoint,
          target: skir.LinkTarget(
            resource: connection.target,
            opposite: opposite,
          ),
        ),
      );
    }
    final named = catalog.namedUse(input.expected);
    if (named != null) {
      final expected = skir.TypeSelection.wrapComplete(named);
      if (catalog.isAbstractRecordSelection(expected)) {
        final selection = await _chooseConcreteType(expected);
        _checkCurrent();
        if (selection == null) throw const _CreationCancelled();
        final request = skir.ValuePreparationRequest(
          catalog: base.generation,
          target: skir.PreparationTarget.wrapRecord(selection),
          suppliedValue: null,
        );
        final prepared = await _prepare(
          request,
          location,
          creationContext,
          publish: (step) {
            _values[location] = step.materialized.recordContent
                .toCreationValue();
          },
        );
        _values.remove(location);
        return prepared.recordContent.toCreationValue();
      }
    }
    throw StateError("No value can be prepared for ${location.path}");
  }

  AuthoringEdit _view() {
    final view = AuthoringEdit.fromDocument(base);
    for (final node in _nodes.values) {
      view.create(node.request.id, node.step.materialized.recordContent);
    }
    final overlays =
        [
          for (final materialization in _materializations(includePending: true))
            (
              location: materialization.location,
              apply: (AuthoringEdit edit) =>
                  edit.applyReferenceMaterialization(materialization),
            ),
          for (final entry in _values.entries)
            (
              location: entry.key,
              apply: (AuthoringEdit edit) {
                switch (edit.set(entry.key, entry.value)) {
                  case PortablePathValue():
                    break;
                  case PortablePathUnavailable(:final message):
                    throw StateError(message);
                }
              },
            ),
        ]..sort(
          (left, right) => left.location.path.segments.length.compareTo(
            right.location.path.segments.length,
          ),
        );
    for (final overlay in overlays) {
      overlay.apply(view);
    }
    for (final reference in _references) {
      view.applyResolvedReference(
        reference.copyWith(materializations: const []),
      );
    }
    return view;
  }

  Future<ResolvedReference> _chooseReference(
    skir.ValueLocation source,
    CreationContext creationContext, {
    skir.ResourceId? chosenTarget,
    skir.ValuePath? chosenOpposite,
  }) async {
    _checkCurrent();
    final view = _view();
    final plans = switch (view.linkPlans(catalog: catalog, source: source)) {
      PortableLinkPlanReady(:final plans) => plans,
      PortableLinkPlanUnavailable(:final message) => throw StateError(message),
    };
    if (plans.length != 1) {
      throw StateError("The reference has ambiguous endpoint bindings");
    }
    final plan = plans.single;
    final endpoint = plan.source.id.endpoint;
    final allowed = creationContext.allowedTargets(endpoint);
    if (allowed != null &&
        chosenTarget != null &&
        !allowed.contains(chosenTarget)) {
      throw StateError("The reference conflicts with the selected destination");
    }
    final constrained = chosenTarget != null || allowed != null;
    for (final reference in _references) {
      final connection = reference.connection;
      if (connection.source.id == plan.source.id) {
        return reference.copyWith(materializations: const []);
      }
      if (connection.counterpart
          case skir.CounterpartChoice_existingWrapper(:final value)
          when value.id == plan.source.id) {
        return ResolvedReference(
          connection: skir.ConnectIntent(
            source: plan.source,
            target: connection.source.source,
            counterpart: skir.CounterpartChoice.wrapExisting(connection.source),
          ),
        );
      }
    }
    final childContext = creationContext.through(endpoint);
    final candidates = <ReferencePickerCandidate<ReferenceChoice>>[];
    final reasons = <String>[];
    for (final target in plan.targets) {
      if (chosenTarget != null && target.resource != chosenTarget) continue;
      if (allowed != null && !allowed.contains(target.resource)) continue;
      if (!childContext.accepts(target.resource, view, catalog)) continue;
      final record = view.resource(target.resource)!;
      final type = catalog.typeSelectionName(record.configuration);
      final title = catalog.appearanceOf(record).label;
      final display = catalog.selectionDisplay(record.configuration);
      final resolved = <ResolvedReference>[];
      if (target.disabledReason case final reason?) {
        reasons.add("$title: $reason");
        continue;
      }
      if (target.automaticCounterpart && chosenOpposite == null) {
        try {
          resolved.add(
            view.resolveReference(catalog: catalog, plan: plan, target: target),
          );
        } on StateError catch (error) {
          reasons.add("$title: ${error.message}");
        }
      }
      if (!target.automaticCounterpart && chosenOpposite == null) {
        for (final collection in target.collections) {
          resolved.add(
            view.resolveReference(
              catalog: catalog,
              plan: plan,
              target: target,
              collection: collection,
            ),
          );
        }
      }
      for (final occurrence in target.existing) {
        if (chosenOpposite != null &&
            occurrence.id.location.path != chosenOpposite) {
          continue;
        }
        final current = switch (view.read(occurrence.id.location)) {
          PortablePathValue(:final value) => value.authoredLink,
          PortablePathUnavailable() => null,
        };
        if (current != null &&
            (current.target.resource != source.resource ||
                current.target.opposite != source.path)) {
          continue;
        }
        final reference = view.resolveReference(
          catalog: catalog,
          plan: plan,
          target: target,
          counterpart: skir.CounterpartChoice.wrapExisting(occurrence),
        );
        if (!resolved.any(
          (other) =>
              other.connection.counterpart == reference.connection.counterpart,
        )) {
          resolved.add(reference);
        }
      }
      for (final reference in resolved) {
        candidates.add(
          ReferencePickerCandidate(
            id: "existing:${target.resource.value}:${candidates.length}",
            value: ReferenceChoice.existing(reference),
            label: title,
            description: _nodes.containsKey(target.resource)
                ? "$type, being created"
                : type,
            searchText: "$title $type ${target.resource.value}",
            display: display,
          ),
        );
      }
      for (final slot in target.creatable.where(
        (_) => chosenOpposite == null,
      )) {
        candidates.add(
          ReferencePickerCandidate(
            id: "counterpart:${target.resource.value}:${candidates.length}",
            value: ReferenceChoice.createCounterpart(slot),
            label: title,
            description:
                "Create ${catalog.typeSelectionName(slot.selection)} in this resource",
            searchText: "$title $type",
            display: display,
          ),
        );
      }
    }
    final existing = candidates
        .where((candidate) => candidate.value is ExistingReference)
        .toList();
    // Ambient preferences and new destinations apply only where nothing
    // explicit constrains this reference; a scope naming several resources
    // asks among exactly those.
    if (!constrained) {
      final preferred = existing
          .where(
            (candidate) => creationContext.preferredResources.contains(
              (candidate.value as ExistingReference)
                  .reference
                  .connection
                  .target,
            ),
          )
          .toList();
      if (preferred.length == 1) {
        return (preferred.single.value as ExistingReference).reference;
      }
      candidates.addAll(_newResourceCandidates(view, plan));
    }
    // A single existing destination with no alternative to create is chosen
    // without asking, such as the one Library a new Book belongs to.
    if (candidates.length == 1 && existing.length == 1) {
      return (existing.single.value as ExistingReference).reference;
    }
    if (candidates.isEmpty) {
      throw StateError(
        constrained
            ? "The selected destination cannot accept this reference${reasons.isEmpty ? '' : ': ${reasons.join('; ')}'}"
            : "No compatible reference destination is available${reasons.isEmpty ? '' : ': ${reasons.join('; ')}'}",
      );
    }
    final presentationDocument = view.toDocument();
    final presentationIssues = ResourceIssues.evaluate(
      document: presentationDocument,
    );
    final choice = await _showReferenceQuestion(
      candidates: candidates,
      presentationDocument: presentationDocument,
      presentationIssues: presentationIssues,
      searchHint:
          "Select or create ${catalog.typeSelectionName(catalog.beginSelection(plan.opposite.resource.definition))}",
    );
    _checkCurrent();
    return switch (choice) {
      null => throw const _CreationCancelled(),
      ExistingReference(:final reference) => reference,
      NewResourceReference(:final template) => await _createReferenceTarget(
        source,
        creationContext,
        childContext,
        template,
      ),
      NewEmbeddedCounterpart(:final slot) => await _createCounterpart(
        plan,
        slot,
        creationContext,
      ),
    };
  }

  Iterable<ReferencePickerCandidate<ReferenceChoice>> _newResourceCandidates(
    PortableAuthoringView view,
    PortableLinkPlan plan,
  ) sync* {
    final source = view.resource(plan.source.source)!;
    final expected = catalog.namedUse(plan.targetType);
    for (final type in catalog.creatableTypes) {
      final configuration = catalog.beginSelection(type);
      final complete = configuration is skir.TypeSelection_completeWrapper;
      if (complete
          ? !catalog.selectionMatches(configuration, plan.targetType)
          : expected == null ||
                !catalog
                    .nominalDefinitions(configuration)
                    .contains(expected.definition)) {
        continue;
      }
      final inverse = catalog
          .endpointBindings(configuration)
          .where((binding) => binding.template.endpoint == plan.opposite.id)
          .toList();
      final compatible =
          inverse.isEmpty ||
          inverse.any(
            (binding) =>
                binding.isAvailable &&
                catalog.selectionMatches(source.configuration, binding.target),
          );
      final label = catalog.typeSelectionName(configuration);
      yield ReferencePickerCandidate(
        id: "create:$configuration",
        value: ReferenceChoice.createResource(
          ResourceCreationTemplate(type: type, configuration: configuration),
        ),
        label: "Create $label",
        description: catalog.selectionDisplay(configuration)?.description ?? "",
        searchText: "create $label",
        display: catalog.selectionDisplay(configuration),
        disabledReason: !complete
            ? "This type requires concrete type arguments"
            : compatible
            ? null
            : "This type cannot refer back to the resource being created",
      );
    }
  }

  Future<ResolvedReference> _createReferenceTarget(
    skir.ValueLocation source,
    CreationContext context,
    CreationContext childContext,
    ResourceCreationTemplate template,
  ) async {
    final target = await resolve(
      ResourceCreationRequest(
        type: template.type,
        configuration: template.configuration,
      ),
      childContext,
    );
    return _chooseReference(source, context, chosenTarget: target);
  }

  Future<ResolvedReference> _createCounterpart(
    PortableLinkPlan plan,
    PortableNewCounterpartChoice slot,
    CreationContext creationContext,
  ) async {
    final view = _view();
    final owner = view.resource(slot.containing.resource)!;
    final collection =
        catalog.collectionItemType(
          catalog.valueTypeAt(
            owner.configuration,
            slot.containing.path,
            value: owner.toCreationValue(),
          ),
        ) !=
        null;
    final item = skir.ItemId(value: "panel:reference:${uuid.v4()}");
    final location = collection
        ? skir.ValueLocation(
            resource: slot.containing.resource,
            path: skir.ValuePath(
              segments: [
                ...slot.containing.path.segments,
                skir.PathSegment.createItem(id: item),
              ],
            ),
          )
        : slot.containing;
    final after = switch (view.read(slot.containing)) {
      PortablePathValue(:final value) => value.authoredItems?.lastOrNull?.id,
      PortablePathUnavailable() => null,
    };
    final request = skir.ValuePreparationRequest(
      catalog: base.generation,
      target: skir.PreparationTarget.wrapRecord(slot.selection),
      suppliedValue: null,
    );
    ReferenceMaterialization materialize(skir.PreparedValue prepared) =>
        collection
        ? ReferenceMaterialization.preparedItem(
            at: slot.containing,
            after: after,
            item: item,
            request: request,
            prepared: prepared,
          )
        : ReferenceMaterialization.preparedRecord(
            at: slot.containing,
            request: request,
            prepared: prepared,
          );
    final counterpartContext = CreationContext(
      preferredResources: [
        plan.source.source,
        ...creationContext.preferredResources,
      ],
    );
    final prepared = await _prepare(
      request,
      location,
      counterpartContext,
      publish: (step) => _embedded[location] = materialize(step.materialized),
    );
    final candidates = catalog
        .referenceLocations(prepared.recordContent)
        .where((reference) => reference.endpoint == plan.opposite.id)
        .map((reference) => reference.path)
        .toList();
    if (candidates.length != 1) {
      throw StateError(
        "The prepared counterpart needs one exact reference location",
      );
    }
    final opposite = skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(
        endpoint: plan.opposite.id,
        location: skir.ValueLocation(
          resource: location.resource,
          path: skir.ValuePath(
            segments: [
              ...location.path.segments,
              ...candidates.single.segments,
            ],
          ),
        ),
      ),
      source: location.resource,
      target: skir.LinkTarget(
        resource: plan.source.source,
        opposite: plan.source.id.location.path,
      ),
    );
    _embedded.remove(location);
    return ResolvedReference(
      connection: skir.ConnectIntent(
        source: plan.source,
        target: location.resource,
        counterpart: skir.CounterpartChoice.wrapExisting(opposite),
      ),
      materializations: [materialize(prepared)],
    );
  }

  void _remember(ResolvedReference reference) {
    final connection = reference.connection;
    final inverse = switch (connection.counterpart) {
      skir.CounterpartChoice_existingWrapper(:final value) => value.id,
      null => null,
      _ => throw StateError("A reference must retain its exact counterpart"),
    };
    for (var index = 0; index < _references.length; index++) {
      final existing = _references[index];
      final other = existing.connection;
      final otherInverse = switch (other.counterpart) {
        skir.CounterpartChoice_existingWrapper(:final value) => value.id,
        _ => null,
      };
      final same = connection.source.id == other.source.id;
      final reversed =
          connection.source.id == otherInverse && inverse == other.source.id;
      if (!same && !reversed) {
        if (inverse != null && inverse == otherInverse) {
          throw StateError(
            "Two references selected the same counterpart location",
          );
        }
        continue;
      }
      if (same &&
          (connection.target != other.target || inverse != otherInverse)) {
        throw StateError("The reference has conflicting answers");
      }
      _references[index] = existing.copyWith(
        materializations: [
          ...existing.materializations,
          ...reference.materializations.where(
            (value) => !existing.materializations.contains(value),
          ),
        ],
      );
      return;
    }
    _references.add(reference);
  }

  /// Resolves the references a prepared [record] at [at] already names, then,
  /// for a resource root, its owner. Each resolution is a question checkpoint,
  /// so stepping back returns to it.
  Future<void> _resolveDefaults(
    skir.AuthoringRecord record,
    skir.ValueLocation at,
    CreationContext creationContext, {
    _CreationQuestion? previous,
  }) async {
    final steps = <_DefaultReference>[
      for (final reference in catalog.referenceLocations(record))
        ?_namedReference(record, at, reference.path, creationContext),
      if (at.path.segments.isEmpty)
        ?_ownerReference(record, at.resource, creationContext),
    ];
    final answered = <(int, _CreationQuestion)>[];
    _CreationQuestion? retry;
    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      if (step.resolved()) continue;
      final question =
          retry ??
          _checkpoint(
            skir.PrepareValueResult.wrapReady(
              skir.PreparedValue(
                content: skir.PreparedContent.wrapRecord(record),
                findings: const [],
              ),
            ),
            answered.lastOrNull?.$2 ?? previous,
          );
      retry = null;
      _questions.add(question);
      try {
        _remember(await step.resolve());
        if (question.presented) answered.add((index, question));
      } on _CreationBack catch (back) {
        final prior = answered.indexWhere(
          (entry) => identical(entry.$2, back.target),
        );
        if (!identical(back.target, question) && prior < 0) rethrow;
        back.target.restore();
        retry = back.target;
        if (prior >= 0) {
          index = answered[prior].$1;
          answered.removeRange(prior, answered.length);
        }
        index--;
      } finally {
        _questions.removeLast();
      }
    }
  }

  /// The reference [record] already names at [path], resolved to its exact
  /// connection, or null when the location holds no link.
  _DefaultReference? _namedReference(
    skir.AuthoringRecord record,
    skir.ValueLocation at,
    skir.ValuePath path,
    CreationContext creationContext,
  ) {
    final value = switch (record.readAt(path)) {
      PortablePathValue(:final value) => value.authoredLink,
      PortablePathUnavailable() => null,
    };
    if (value == null) return null;
    final id = skir.LinkOccurrenceId(
      endpoint: value.endpoint,
      location: skir.ValueLocation(
        resource: at.resource,
        path: skir.ValuePath(segments: [...at.path.segments, ...path.segments]),
      ),
    );
    return _DefaultReference(
      resolved: () => _references.any(
        (reference) =>
            reference.connection.source.id == id ||
            switch (reference.connection.counterpart) {
              skir.CounterpartChoice_existingWrapper(:final value) =>
                value.id == id,
              _ => false,
            },
      ),
      resolve: () => _chooseReference(
        id.location,
        creationContext,
        chosenTarget: value.target.resource,
        chosenOpposite: value.target.opposite,
      ),
    );
  }

  /// The owner of the created resource [resource], when its type is owned.
  ///
  /// Every owned resource needs its owner, whether or not the back reference
  /// field is nullable and whether or not the creation names a destination.
  /// A type with a back reference links through it, choosing the single or
  /// preferred owner or asking; a type owned only from the owner side asks for
  /// an owner and links from the owner's owning field.
  _DefaultReference? _ownerReference(
    skir.AuthoringRecord record,
    skir.ResourceId resource,
    CreationContext creationContext,
  ) {
    final type = record.configuration.definition;
    if (type == null) return null;
    final ownerships = [
      for (final ownership in catalog.ownershipRelations)
        if (catalog.isNominalSubtype(
          type,
          ownership.member.resource.definition,
        ))
          ownership,
    ];
    if (ownerships.isEmpty) return null;
    // A destination named by the creation decides which ownership applies.
    final constrained = ownerships
        .where(
          (ownership) =>
              creationContext.allowedTargets(ownership.member.id) != null,
        )
        .toList();
    final applicable = constrained.isEmpty ? ownerships : constrained;
    bool owned() => applicable.any(
      (ownership) => _view().links.any(
        (link) =>
            link.contract == ownership.relation &&
            switch (ownership.member.slot) {
                  skir.EndpointSlot.first => link.first,
                  _ => link.second,
                } ==
                resource,
      ),
    );
    for (final ownership in applicable) {
      final backReference = catalog
          .referenceLocations(record)
          .where((reference) => reference.endpoint == ownership.member.id)
          .firstOrNull;
      if (backReference == null) continue;
      return _DefaultReference(
        resolved: owned,
        resolve: () => _chooseReference(
          skir.ValueLocation(resource: resource, path: backReference.path),
          creationContext,
        ),
      );
    }
    return _DefaultReference(
      resolved: owned,
      resolve: () => _chooseOwner(resource, applicable, creationContext),
    );
  }

  /// Links [member] from the owning field of an owner it chooses among
  /// [ownerships], for types owned only from the owner side.
  Future<ResolvedReference> _chooseOwner(
    skir.ResourceId member,
    List<OwnershipRelation> ownerships,
    CreationContext creationContext,
  ) async {
    _checkCurrent();
    final view = _view();
    final document = view.toDocument();
    final candidates = <ReferencePickerCandidate<ReferenceChoice>>[];
    final reasons = <String>[];
    for (final ownership in ownerships) {
      final allowed = creationContext.allowedTargets(ownership.member.id);
      final ownerContext = creationContext.through(ownership.member.id);
      for (final MapEntry(key: owner, value: record)
          in view.resources.entries) {
        if (owner == member) continue;
        if (allowed != null && !allowed.contains(owner)) continue;
        if (!ownerContext.accepts(owner, view, catalog)) continue;
        final field = catalog
            .owningFields(record.configuration)
            .where((field) => field.ownership.relation == ownership.relation)
            .firstOrNull;
        if (field == null) continue;
        final location = skir.ValueLocation(resource: owner, path: field.path);
        final source = document.isLinkCollection(location)
            ? skir.ValueLocation(
                resource: owner,
                path: skir.ValuePath(
                  segments: [
                    ...field.path.segments,
                    skir.PathSegment.createItem(
                      id: skir.ItemId(value: "panel:owner:${uuid.v4()}"),
                    ),
                  ],
                ),
              )
            : location;
        final title = catalog.appearanceOf(record).label;
        final link = automaticLink(view, catalog, source, member);
        if (link == null) {
          reasons.add("$title cannot hold this resource");
          continue;
        }
        candidates.add(
          ReferencePickerCandidate(
            id: "owner:${owner.value}:${candidates.length}",
            value: ReferenceChoice.existing(
              view.resolveReference(
                catalog: catalog,
                plan: link.plan,
                target: link.target,
              ),
            ),
            label: title,
            description: catalog.typeSelectionName(record.configuration),
            searchText:
                "$title ${catalog.typeSelectionName(record.configuration)}",
            display: catalog.selectionDisplay(record.configuration),
          ),
        );
      }
    }
    ResolvedReference reference(
      ReferencePickerCandidate<ReferenceChoice> candidate,
    ) => (candidate.value as ExistingReference).reference;
    final preferred = candidates
        .where(
          (candidate) => creationContext.preferredResources.contains(
            reference(candidate).connection.source.source,
          ),
        )
        .toList();
    if (candidates.length == 1) return reference(candidates.single);
    if (preferred.length == 1) return reference(preferred.single);
    if (candidates.isEmpty) {
      throw StateError(
        "No owner can hold this resource${reasons.isEmpty ? '' : ': ${reasons.join('; ')}'}",
      );
    }
    final presentationDocument = view.toDocument();
    final choice = await _showReferenceQuestion(
      candidates: candidates,
      presentationDocument: presentationDocument,
      presentationIssues: ResourceIssues.evaluate(
        document: presentationDocument,
      ),
      searchHint: "Select the owner",
    );
    _checkCurrent();
    return switch (choice) {
      ExistingReference(:final reference) => reference,
      _ => throw const _CreationCancelled(),
    };
  }

  Iterable<ReferenceMaterialization> _materializations({
    bool includePending = false,
  }) {
    return <ReferenceMaterialization>{
      for (final reference in _references) ...reference.materializations,
      if (includePending) ..._embedded.values,
    }.toList()..sort(
      (left, right) => left.location.path.segments.length.compareTo(
        right.location.path.segments.length,
      ),
    );
  }

  void requireReady() {
    _checkCurrent();
    if (_embedded.isNotEmpty ||
        _values.isNotEmpty ||
        _nodes.values.any(
          (node) => node.step is! skir.PrepareValueResult_readyWrapper,
        )) {
      throw StateError("Creation still requires a value");
    }
  }

  void apply(AuthoringEdit edit) {
    requireReady();
    if (edit.generation != base.generation) throw const _CreationCancelled();
    for (final reference in _references) {
      final target = reference.connection.target;
      if (_nodes.containsKey(target)) continue;
      final original = base.resource(target);
      if (original == null ||
          edit.resource(target)?.configuration != original.configuration) {
        throw const EditPreparationFailure(
          "The selected reference destination changed during creation",
        );
      }
    }
    final locations = <skir.ValueLocation>{
      for (final materialization in _materializations())
        materialization.location,
      for (final reference in _references) ...[
        reference.connection.source.id.location,
        if (reference.connection.counterpart
            case skir.CounterpartChoice_existingWrapper(:final value))
          value.id.location,
      ],
    };
    for (final location in locations) {
      final original = base.resource(location.resource);
      if (original == null) continue;
      if (edit.resource(location.resource)?.configuration !=
              original.configuration ||
          edit.expect(location) != base.read(location)) {
        throw const EditPreparationFailure(
          "The selected reference destination changed during creation",
        );
      }
    }
    for (final node in _nodes.values) {
      edit.createPrepared(node.request.id, node.step.materialized);
    }
    for (final materialization in _materializations()) {
      edit.applyReferenceMaterialization(materialization);
    }
    for (final reference in _references) {
      edit.applyResolvedReference(
        reference.copyWith(materializations: const []),
      );
    }
    for (final node in _nodes.values) {
      if (!node.context.accepts(node.request.id, edit, catalog)) {
        throw const EditPreparationFailure(
          "The selected destination no longer matches the creation request",
        );
      }
    }
    for (final node in _nodes.values) {
      edit.placeCreatedResource(node.request);
    }
    _checkCurrent();
  }
}

extension on skir.AuthoringRecord {
  skir.DataValue toCreationValue() {
    final actual = switch (configuration) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => throw StateError("A prepared record must have a concrete type"),
    };
    return skir.DataValue.createNamed(
      actualType: actual,
      payload: skir.DataValue.createRecord(fields: fields),
    );
  }
}

extension on ReferenceMaterialization {
  skir.ValueLocation get location => switch (this) {
    ReferenceValueInsertion(:final intent) => intent.at,
    PreparedReferenceInsertion(:final at) ||
    PreparedReferenceRecord(:final at) => at,
  };
}

/// One reference a prepared record still needs: whether it is already
/// resolved, and how to resolve it.
final class _DefaultReference {
  const _DefaultReference({required this.resolved, required this.resolve});

  final bool Function() resolved;
  final Future<ResolvedReference> Function() resolve;
}
