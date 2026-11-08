import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// One operation a Realm offers on its resources, as its declaration
/// presents it.
///
/// The [effect] is what running the operation does to the document; the
/// Realm double prepares it as the operation's preview and keeps the result
/// once the user confirms. A [disabledBecause] reason makes the Realm offer
/// the operation disabled.
final class RealmOperation {
  const RealmOperation(
    this.name, {
    required this.group,
    String? label,
    this.inspector = RealmOperationInspector.outlined,
    this.shortcut,
    this.confirmation,
    this.effect,
    this.disabledBecause,
  }) : label = label ?? name;

  /// Duplicates the selected resources; an edit button in the inspector.
  const RealmOperation.duplicate({String? disabledBecause})
    : this(
        "Duplicate",
        group: skir.OperationGroup.edit,
        disabledBecause: disabledBecause,
      );

  /// Moves the selected resources by dropping them on a new owner; it stays
  /// out of the inspector.
  const RealmOperation.moveTo({String? disabledBecause})
    : this(
        "MoveToOwner",
        label: "Move to",
        group: skir.OperationGroup.organize,
        inspector: RealmOperationInspector.hidden,
        disabledBecause: disabledBecause,
      );

  /// Deletes the selected resources once the user holds; bound to the
  /// delete key and shown as a destructive filled button.
  const RealmOperation.delete({String? disabledBecause})
    : this(
        "Delete",
        group: skir.OperationGroup.destructive,
        inspector: RealmOperationInspector.filled,
        shortcut: skir.OperationShortcut.delete,
        confirmation: const RealmConfirmation(
          one: "Delete this resource and what it owns?",
          many: "Delete {count} resources and what they own?",
        ),
        effect: _delete,
        disabledBecause: disabledBecause,
      );

  /// The declaration name; also names its capability.
  final String name;
  final String label;
  final skir.OperationGroup group;
  final RealmOperationInspector inspector;
  final skir.OperationShortcut? shortcut;
  final RealmConfirmation? confirmation;
  final void Function(AuthoringEdit edit, List<skir.ResourceId> targets)?
  effect;
  final String? disabledBecause;

  static void _delete(AuthoringEdit edit, List<skir.ResourceId> targets) {
    for (final target in targets) {
      edit.delete(target);
    }
  }

  /// The capability that prepares this operation.
  skir.CapabilityId get capability =>
      skir.CapabilityId(value: "operations:$name");

  skir.ResourceOperationDefinition get definition =>
      skir.ResourceOperationDefinition(
        id: skir.ResourceOperationId(
          artifact: "typewriter",
          sourcePart: "main",
          declaration: "com.typewritermc.operations.$name",
        ),
        targets: skir.OperationTargets(
          subject: skir.ResourceTarget.anyResource,
          cardinality: skir.OperationCardinality.selection,
        ),
        capability: capability,
        drop: inspector == RealmOperationInspector.hidden
            ? skir.OperationDrop(
                input: editorRootPath.field("destination"),
                hint: "Move here",
              )
            : null,
        presentation: skir.OperationPresentation(
          label: label,
          description: "$name the resource",
          icon: "",
          group: group,
          order: 0,
          tone: group == skir.OperationGroup.destructive
              ? skir.HeaderActionTone.destructive
              : skir.HeaderActionTone.neutral,
          confirmation: switch (confirmation) {
            null => null,
            final confirmation => skir.OperationConfirmation(
              outcomeOne: confirmation.one,
              outcomeMany: confirmation.many,
            ),
          },
          inspector: switch (inspector) {
            RealmOperationInspector.hidden => skir.OperationInspector.hidden,
            RealmOperationInspector.outlined =>
              skir.OperationInspector.wrapButton(skir.ButtonVariant.outlined),
            RealmOperationInspector.filled =>
              skir.OperationInspector.wrapButton(skir.ButtonVariant.filled),
          },
          shortcut: shortcut,
        ),
      );

  @override
  String toString() => name;
}

/// How the inspector shows an operation.
enum RealmOperationInspector { hidden, outlined, filled }

/// The outcome line a Realm declares for a held operation: [one] for one
/// target, [many] for several with "{count}" for their number.
final class RealmConfirmation {
  const RealmConfirmation({required this.one, required this.many});

  final String one;
  final String many;
}

/// The authoring side of one Realm: its saved document, the saves it
/// received, the operations it offers and the publication it reports.
///
/// Replaces the Realm's authoring capabilities, the boundary the panel's
/// workspace reads saved content from and sends edits to. A confirmed save is
/// kept: the next observation shows it, as it would after a real save. It
/// checks no expectations and enforces no rules; component tests and
/// journeys prove those on a real Realm.
///
/// Saves are confirmed as they arrive unless [holdSaves] is set; then each
/// waits in [saves] until the test answers it, the way a slow or lost reply
/// reaches the panel.
final class FakeRealm {
  FakeRealm({
    required this.scope,
    required this.name,
    required AuthoringDocument document,
    List<RealmOperation> operations = const [],
  }) : _operations = operations,
       _observation = AsyncData(_withCapabilities(document, operations)) {
    publication = TestPublicationRepository(
      scope,
      initial: PublicationObservation.available(
        skir.PublicationView(
          id: skir.PublicationViewId(value: "test:empty"),
          status: skir.PublicationStatus.createEmpty(notices: const []),
        ),
      ),
    );
  }

  final AuthoringScope scope;
  final String name;
  final List<RealmOperation> _operations;
  AsyncValue<AuthoringDocument> _observation;
  final _listeners = <void Function()>[];
  final _saves = <RealmSave>[];
  var _closed = false;

  /// How long the Realm takes to answer a request.
  Duration latency = Duration.zero;

  /// Whether saves wait in [saves] for the test to answer them; otherwise
  /// the Realm confirms each one after [latency].
  bool holdSaves = false;

  /// The error the next refresh of the saved document fails with; null
  /// lets refreshes read the saved document.
  Object? refreshFailure;

  /// Replaces how the Realm prepares a value for a new resource or field;
  /// by default it fills every field with its catalog default.
  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?
  answerPrepareValue;

  /// Replaces how the Realm answers one step of an interactive preparation;
  /// by default it asks for every unfilled field.
  Future<skir.PrepareValueResult> Function(skir.PreparationOperation step)?
  answerPrepareStep;

  /// Replaces where the Realm lets dragged resources land; by default
  /// nowhere.
  Future<skir.ResolveDropCandidatesResult> Function(
    skir.ResolveDropCandidatesRequest request,
  )?
  answerDropCandidates;

  /// Replaces which operations the Realm offers on resources; by default
  /// the operations the world seeded.
  Future<skir.ResolveResourceOperationsResult> Function(
    skir.ResolveResourceOperationsRequest request,
  )?
  answerResourceOperations;

  /// Replaces how the Realm prepares an operation the user runs; by default
  /// it previews the seeded operation's effect.
  Future<skir.AuthoringActionResult> Function(
    skir.PrepareAuthoringActionRequest request,
  )?
  answerPrepareAction;

  /// Replaces what the Realm answers to a live presentation search, such as
  /// the candidates of an operation field; by default it has no search.
  Stream<skir.RealmPresentationSearchUpdate> Function(
    skir.RealmPresentationSearchRequest request,
  )?
  answerWatchSearch;

  /// Replaces how the Realm answers a refresh of the saved document, such as
  /// a refresh the test answers later; by default it reads [document].
  Future<AuthoringDocument> Function()? answerRefresh;

  /// Replaces how the Realm answers a resource search; by default it has no
  /// search.
  Future<skir.SearchAuthoringResponse> Function(
    skir.SearchAuthoringRequest request,
  )?
  answerSearch;

  /// The publication the Realm reports for its content.
  late final TestPublicationRepository publication;

  /// The saved document, including every save the Realm confirmed.
  AuthoringDocument get document => _observation.requireValue;

  /// Every save the Realm received, in the order it received them.
  List<RealmSave> get saves => List.unmodifiable(_saves);

  /// How many times the panel asked the Realm to prepare an operation.
  int get prepares => _prepares;
  var _prepares = 0;

  /// Whether the Realm is away, as when its own link is cut while the panel
  /// stays connected: nothing receives a save until it [returns].
  bool away = false;

  /// Why the panel cannot prepare a save, such as missing credentials; null
  /// lets saves be sent. Nothing reaches the Realm while it is set.
  String? unpreparable;

  /// How many saves the panel sent while the Realm was [away]; none of them
  /// reached it.
  int missedSaves = 0;

  /// Takes the Realm away; see [away].
  void goAway() => away = true;

  /// Brings the Realm back; later saves reach it.
  void returns() => away = false;

  /// Applies an edit someone else saved, the way a second author's save
  /// reaches this panel.
  void remoteChange(void Function(AuthoringEdit edit) change) {
    final edit = AuthoringEdit.fromDocument(document);
    change(edit);
    serve(_observed(edit));
  }

  var _observations = 0;

  /// [edit] as the Realm saves it: a document with a new observation.
  AuthoringDocument _observed(AuthoringEdit edit) =>
      _withObservation(edit.toDocument());

  /// [document] as the Realm saves it, with a new observation.
  AuthoringDocument _withObservation(AuthoringDocument document) =>
      document.copyWith(
        confirmedObservation: skir.AuthoringObservationId(
          value: "${scope.realmId.id}:saved:${++_observations}",
        ),
      );

  /// Replaces the saved document, such as one typed by a newer catalog.
  void serve(AuthoringDocument document) => _publish(AsyncData(document));

  /// Makes the saved document unreadable with [error], as when the Realm
  /// cannot be reached.
  void fail(Object error) =>
      _publish(AsyncError<AuthoringDocument>(error, StackTrace.current));

  void _publish(AsyncValue<AuthoringDocument> next) {
    _observation = next;
    for (final listener in [..._listeners]) {
      listener();
    }
  }

  /// The edit each committed submission carried, by key.
  final _committed = <String, skir.PreparedEdit>{};

  /// The reply to a committed submission: the current saved state.
  skir.CommitPreparedEditResponse get _committedReply =>
      skir.CommitPreparedEditResponse.wrapCommitted(document.savedState);

  Future<skir.CommitPreparedEditResponse> _receive(
    skir.CommitPreparedEditRequest commit,
  ) {
    final save = RealmSave._(this, commit.edit, commit.submission);
    _saves.add(save);
    if (_committed[commit.submission] case final first?) {
      // A repeat applies nothing and answers with the current saved state.
      unawaited(
        _reply(
          () => save._response.complete(
            first == commit.edit
                ? _committedReply
                : _submissionReused(commit.submission),
          ),
        ),
      );
    } else if (!holdSaves) {
      unawaited(_reply(save.confirm));
    }
    return save._response.future;
  }

  Future<void> _reply(void Function() answer) async {
    await Future<void>.delayed(latency);
    if (!_closed) answer();
  }

  Future<T> _answer<T>(T Function() answer) async {
    await Future<void>.delayed(latency);
    return answer();
  }

  /// The save boundary, for components composed without the panel, such as
  /// stories; the panel reaches it through [overrides].
  late final RealmEditPersistence persistence = RealmEditPersistence(
    // Resources are named as the panel's Realm persistence names them, so
    // the Realm's inbox and activity attribute these saves to the Realm.
    reservations: (edits) => {
      for (final edit in edits)
        for (final resource in edit.editedResources)
          (scope.organizationId, scope.realmId, resource),
    },
    observe: () async {
      if (refreshFailure case final error?) throw error;
      return answerRefresh?.call() ?? document;
    },
    request: (commit) => PreparedCommit(
      id: commit.submission,
      label: "Save to $name",
      resources: {
        for (final resource in commit.edit.editedResources)
          (scope.organizationId, scope.realmId, resource),
      },
      replay: SubmissionReplay.identicalRequest,
      send: () async {
        if (unpreparable case final message?) {
          return SubmissionResult.notSubmitted(message: message);
        }
        if (away) {
          missedSaves++;
          return const SubmissionResult.undelivered(
            message: "Nothing answered; the service may be away",
          );
        }
        final response = await _receive(commit);
        return switch (response) {
          skir.CommitPreparedEditResponse_internalErrorWrapper() ||
          skir.CommitPreparedEditResponse_unknown() =>
            SubmissionResult.uncertain(
              message: "The Realm's answer is unknown",
              cause: response,
              stackTrace: StackTrace.current,
            ),
          skir.CommitPreparedEditResponse_committedWrapper() =>
            SubmissionResult.confirmed(response),
          _ => SubmissionResult.rejected(
            message: response.rejectionMessage,
            response: response,
          ),
        };
      },
    ),
  );

  /// The authoring commands, for components composed without the panel.
  late final AuthoredResourceCommands commands = AuthoredResourceCommands(
    previewTypeArguments: ({required resource, required requested}) async =>
        throw StateError("The Realm double changes no type arguments"),
    prepareTypeArguments: (_) async =>
        throw StateError("The Realm double changes no type arguments"),
    prepareValue: (request) =>
        answerPrepareValue?.call(request) ??
        _answer(() => document.prepareValue(request)),
    prepareStep: (step) =>
        answerPrepareStep?.call(step) ??
        _answer(() => document.prepareStep(step)),
    invokeCommand: ({required capabilityId, required payload}) async =>
        throw StateError("The Realm double runs no commands"),
    search: (request) async =>
        answerSearch?.call(request) ??
        (throw StateError("The Realm double has no search")),
    watchSearch: (request) =>
        answerWatchSearch?.call(request) ??
        Stream.error(StateError("The Realm double has no search")),
    reload: () async {},
    resolveResourceOperations: (request) =>
        answerResourceOperations?.call(request) ??
        _answer(
          () => skir.ResolveResourceOperationsResult.wrapResolved(
            skir.ResolvedResourceOperations(
              operations: [
                for (final operation in _operations)
                  skir.ResolvedResourceOperation(
                    definition: operation.definition,
                    availability: switch (operation.disabledBecause) {
                      null => skir.OperationAvailability.enabled,
                      final reason => skir.OperationAvailability.wrapDisabled(
                        reason,
                      ),
                    },
                  ),
              ],
            ),
          ),
        ),
    resolveDropCandidates: (request) =>
        answerDropCandidates?.call(request) ??
        _answer(() => skir.ResolveDropCandidatesResult.wrapResolved(const [])),
    prepareAuthoringAction: (request) {
      _prepares++;
      return answerPrepareAction?.call(request) ??
          _answer(() {
            final operation = _operations.firstWhere(
              (operation) => operation.capability == request.capability,
              orElse: () => throw StateError(
                "The Realm offers no operation for ${request.capability.value}",
              ),
            );
            final edit = AuthoringEdit.fromDocument(document);
            operation.effect?.call(edit, request.invocation.targets.toList());
            return skir.AuthoringActionResult.createPreview(
              invocationId: request.invocation.invocationId,
              inputRevision: request.inputRevision,
              edit: edit.prepare(),
              selection: skir.OperationSelectionEffect.unchanged,
            );
          });
    },
  );

  /// Replaces the Realm's authoring capabilities for [scope].
  List<Override> get overrides => [
    realmPublicationRepositoryProvider.overrideWith(
      (ref, ids) => _serve(
        ids.$1,
        ids.$2,
        ConnectedPublicationRepository(
          publication,
          () => ref.watch(natsProvider.future),
        ),
      ),
    ),
    confirmedAuthoringDocumentProvider.overrideWith((ref, requested) {
      _serve(requested.organizationId, requested.realmId, null);
      _listeners.add(ref.invalidateSelf);
      ref.onDispose(() => _listeners.remove(ref.invalidateSelf));
      return _observation;
    }),
    realmEditPersistenceProvider.overrideWith(
      (ref, requested) =>
          _serve(requested.organizationId, requested.realmId, persistence),
    ),
    authoredResourceCommandsProvider.overrideWith(
      (ref, requested) =>
          _serve(requested.organizationId, requested.realmId, commands),
    ),
  ];

  T _serve<T>(skir.RecordId organization, skir.RecordId realm, T value) {
    if (organization != scope.organizationId || realm != scope.realmId) {
      throw StateError(
        "The test world seeds the realm $name at $scope, "
        "not ${AuthoringScope(organizationId: organization, realmId: realm)}",
      );
    }
    return value;
  }

  /// Ends the Realm's observations.
  Future<void> close() async {
    _closed = true;
    _listeners.clear();
    await publication.close();
  }
}

/// One save the Realm received, answered by the Realm or, while it holds
/// saves, by the test.
final class RealmSave {
  RealmSave._(this._realm, this.edit, this.submission);

  final FakeRealm _realm;

  /// The edit the panel asked the Realm to save.
  final skir.PreparedEdit edit;

  /// The key the panel named this save attempt with.
  final String submission;

  final _response = Completer<skir.CommitPreparedEditResponse>();

  /// Whether the save was answered or its reply lost.
  bool get answered => _response.isCompleted;

  /// Keeps the edit and answers with the saved document, which shows it.
  /// [saved] replaces the document the Realm keeps, for a save another
  /// author's change reached first. Without [observed], the Realm's
  /// observation lags behind its reply: the reply settles the save, and other
  /// readers see the document once they refresh.
  void confirm({AuthoringDocument? saved, bool observed = true}) {
    final document = switch (saved) {
      null => _realm._observed(
        AuthoringEdit.fromDocument(_realm.document)..applyPrepared(edit),
      ),
      // Every saved state carries its observation, as the Realm's reply does.
      AuthoringDocument(confirmedObservation: null) => _realm._withObservation(
        saved,
      ),
      _ => saved,
    };
    if (observed) {
      _realm.serve(document);
    } else {
      _realm._observation = AsyncData(document);
    }
    _realm._committed[submission] = edit;
    _response.complete(_realm._committedReply);
  }

  /// Refuses the save with [response] and keeps the saved document.
  void reject(skir.CommitPreparedEditResponse response) {
    if (response is skir.CommitPreparedEditResponse_committedWrapper) {
      throw ArgumentError("A refusal cannot answer committed; use confirm()");
    }
    _response.complete(response);
  }

  /// Loses the reply with [error], so the panel never learns whether the
  /// Realm kept the edit.
  void loseReply([Object? error]) => _response.completeError(
    error ?? StateError("The Realm's reply was lost"),
  );

  /// Keeps the edit but loses the reply with [error], as when the Realm saved
  /// it and restarted before answering. A resend under the same key is
  /// answered with the current saved state.
  void keepAndLoseReply([Object? error]) {
    _realm._observation = AsyncData(
      _realm._observed(
        AuthoringEdit.fromDocument(_realm.document)..applyPrepared(edit),
      ),
    );
    _realm._committed[submission] = edit;
    loseReply(error);
  }
}

/// The Realm's refusal of [submission] reused for a different edit.
skir.CommitPreparedEditResponse _submissionReused(String submission) =>
    skir.CommitPreparedEditResponse.wrapInvalidError(
      skir.AuthoringInvalid(
        diagnostics: [
          skir.AuthoringDiagnostic(
            code: "submission_reused",
            message:
                "Submission $submission was committed with a different edit.",
            resource: null,
            path: null,
          ),
        ],
      ),
    );

/// [document] whose catalog declares a capability for each of [operations],
/// so the panel can prepare them.
AuthoringDocument _withCapabilities(
  AuthoringDocument document,
  List<RealmOperation> operations,
) {
  if (operations.isEmpty) return document;
  final snapshot = document.catalog.snapshot.toMutable()
    ..capabilities = [
      ...document.catalog.snapshot.capabilities,
      for (final operation in operations)
        skir.CapabilityDefinition.createAuthoring(
          capabilityId: operation.capability,
          targets: operation.definition.targets,
          input: null,
        ),
    ];
  return document.copyWith(catalog: CheckedEditorCatalog(snapshot.toFrozen()));
}

/// How the Realm double prepares values: from the catalog defaults of the
/// saved document.
extension RealmPreparation on AuthoringDocument {
  /// The value the Realm double prepares for [request]: what the request
  /// supplies, else every field's catalog default.
  skir.PreparedValue prepareValue(skir.ValuePreparationRequest request) {
    if (catalog.snapshot.generation != request.catalog) {
      throw StateError("The Realm's catalog changed");
    }
    final defaults = this;
    if (request.target case skir.PreparationTarget_valueWrapper(:final value)) {
      final named = catalog.namedUse(value);
      final prepared = named == null
          ? defaults.defaultValue(value)
          : skir.DataValue.createNamed(
              actualType: named,
              payload: skir.DataValue.createRecord(
                fields: [
                  for (final field in catalog.fields(
                    skir.TypeSelection.wrapComplete(named),
                  ))
                    skir.FieldValue(
                      name: field.template.key,
                      value: defaults.defaultValue(field.type),
                    ),
                ],
              ),
            );
      return skir.PreparedValue(
        content: skir.PreparedContent.wrapValue(
          request.suppliedValue ?? prepared,
        ),
        findings: const [],
      );
    }

    return skir.PreparedValue(
      content: skir.PreparedContent.wrapRecord(
        skir.AuthoringRecord(
          types: const [],
          configuration: request.recordSelection,
          fields: [
            for (final field in catalog.fields(request.recordSelection))
              skir.FieldValue(
                name: field.template.key,
                value:
                    request.recordSuppliedFields
                        .firstWhereOrNull(
                          (value) => value.name == field.template.key,
                        )
                        ?.value ??
                    defaults.defaultValue(field.type),
              ),
          ],
        ),
      ),
      findings: const [],
    );
  }

  /// The Realm double's answer to one preparation step: the record with
  /// what the step supplies and catalog defaults, asking for every field
  /// still unfilled. Native constructor captures belong to Realm tests.
  skir.PrepareValueResult prepareStep(skir.PreparationOperation operation) {
    final document = this;
    late skir.PreparationTarget target;
    late skir.AuthoringRecord record;
    switch (operation) {
      case skir.PreparationOperation_startWrapper(:final value):
        if (value.catalog != document.generation) {
          throw StateError("The Realm's catalog changed");
        }
        target = value.target;
        record = skir.AuthoringRecord(
          types: const [],
          configuration: value.recordSelection,
          fields: [
            for (final field in document.catalog.fields(value.recordSelection))
              skir.FieldValue(
                name: field.template.key,
                value:
                    value.recordSuppliedFields
                        .firstWhereOrNull(
                          (input) => input.name == field.template.key,
                        )
                        ?.value ??
                    document.defaultValue(field.type),
              ),
          ],
        );
      case skir.PreparationOperation_resumeWrapper(:final value):
        if (value.draft.catalog != document.generation) {
          throw StateError("The Realm's catalog changed");
        }
        target = value.draft.target;
        record = switch (value.draft.content) {
          skir.PreparedContent_recordWrapper(:final value) => value,
          _ => throw StateError(
            "The Realm double prepares record content only",
          ),
        };
        for (final answer in value.answers) {
          record = switch (record.replaceAt(answer.path, answer.value)) {
            PortablePathValue(:final value) => value,
            PortablePathUnavailable(:final message) => throw StateError(
              message,
            ),
          };
        }
      case skir.PreparationOperation_unknown():
        throw StateError("Unknown preparation operation");
    }
    final required = <skir.RequiredInput>[];
    void visit(skir.DataValue value, skir.ValuePath path) {
      if (value.authoredPayload == skir.DataValue.unfilled) {
        final expected = document.catalog.valueTypeAt(
          record.configuration,
          path,
        );
        if (expected != null) {
          required.add(skir.RequiredInput(path: path, expected: expected));
        }
        return;
      }
      for (final field
          in value.authoredRecord?.fields ?? const <skir.FieldValue>[]) {
        visit(
          field.value,
          skir.ValuePath(
            segments: [
              ...path.segments,
              skir.PathSegment.createField(name: field.name),
            ],
          ),
        );
      }
      for (final item in value.authoredItems ?? const <skir.ListItem>[]) {
        visit(
          item.value,
          skir.ValuePath(
            segments: [
              ...path.segments,
              skir.PathSegment.createItem(id: item.id),
            ],
          ),
        );
      }
    }

    visit(
      skir.DataValue.createRecord(fields: record.fields),
      skir.ValuePath(segments: const []),
    );
    final content = skir.PreparedContent.wrapRecord(record);
    if (required.isEmpty) {
      return skir.PrepareValueResult.wrapReady(
        skir.PreparedValue(content: content, findings: const []),
      );
    }
    return skir.PrepareValueResult.wrapNeedsInput(
      skir.PreparationDraft(
        catalog: document.generation,
        target: target,
        content: content,
        pendingDefaults: const [],
        requiredInputs: required,
        findings: const [],
      ),
    );
  }
}
