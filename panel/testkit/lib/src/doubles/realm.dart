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

  /// Deletes the selected resources after the user confirms; bound to the
  /// delete key and shown as a destructive filled button.
  const RealmOperation.delete({String? disabledBecause})
    : this(
        "Delete",
        group: skir.OperationGroup.destructive,
        inspector: RealmOperationInspector.filled,
        shortcut: skir.OperationShortcut.delete,
        confirmation: const RealmConfirmation(
          title: "Delete resources",
          message: "Delete the selected resources?",
          confirm: "Delete",
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
          confirmation: null,
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

/// The confirmation a Realm asks before it applies an operation.
final class RealmConfirmation {
  const RealmConfirmation({
    required this.title,
    required this.message,
    required this.confirm,
  });

  final String title;
  final String message;
  final String confirm;
}

/// The authoring side of one Realm: its saved document, the operations it
/// offers and the publication it reports.
///
/// Replaces the Realm's authoring capabilities, the boundary the panel's
/// workspace reads saved content from and sends edits to. A saved edit is
/// kept: the next observation shows it, as it would after a real save. It
/// checks no expectations and enforces no rules; component tests and
/// journeys prove those on a real Realm.
final class FakeRealm {
  FakeRealm({
    required this.scope,
    required this.name,
    required AuthoringDocument document,
    List<RealmOperation> operations = const [],
  }) : _operations = operations,
       _transport = ScriptedAuthoringTransport(
         AsyncData(_withCapabilities(document, operations)),
       ) {
    _transport.addListener(_keepSavedEdits);
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
  final ScriptedAuthoringTransport _transport;

  /// How long the Realm takes to answer a request.
  Duration latency = Duration.zero;

  /// The publication the Realm reports for its content.
  late final TestPublicationRepository publication;

  var _answered = 0;

  /// The saved document, including every edit the Realm kept.
  AuthoringDocument get document => _transport.observation.requireValue;

  /// Applies an edit someone else saved, the way a second author's save
  /// reaches this panel.
  void remoteChange(void Function(AuthoringEdit edit) change) {
    final edit = AuthoringEdit.fromDocument(document);
    change(edit);
    _transport.publish(AsyncData(edit.toDocument()));
  }

  void _keepSavedEdits() {
    while (_answered < _transport.requests.length) {
      final index = _answered++;
      final edit = _transport.requests[index].edit;
      unawaited(
        _reply(() {
          final saved = AuthoringEdit.fromDocument(document)
            ..applyPrepared(edit);
          _transport.confirm(index, saved.toDocument());
        }),
      );
    }
  }

  Future<void> _reply(void Function() answer) async {
    await Future<void>.delayed(latency);
    answer();
  }

  Future<T> _answer<T>(T Function() answer) async {
    await Future<void>.delayed(latency);
    return answer();
  }

  AuthoredResourceCommands _commands() => fixtureAuthoringCommands(
    _transport,
    resolveResourceOperations: (_) => _answer(
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
    prepareAuthoringAction: (request) => _answer(() {
      final operation = _operations.firstWhere(
        (operation) => operation.capability == request.capability,
        orElse: () => throw StateError(
          "The Realm offers no operation for ${request.capability.value}",
        ),
      );
      final edit = AuthoringEdit.fromDocument(document);
      operation.effect?.call(edit, request.invocation.targets.toList());
      final confirmation = operation.confirmation;
      return skir.AuthoringActionResult.createPreview(
        invocationId: request.invocation.invocationId,
        inputRevision: request.inputRevision,
        edit: edit.prepare(),
        confirmation: confirmation == null
            ? null
            : skir.OperationConfirmation(
                title: confirmation.title,
                message: confirmation.message,
                confirmationLabel: confirmation.confirm,
              ),
        selection: skir.OperationSelectionEffect.unchanged,
      );
    }),
  );

  /// Replaces the Realm's authoring capabilities for [scope].
  List<Override> get overrides => [
    realmPublicationRepositoryProvider.overrideWith(
      (ref, ids) => _serve(ids.$1, ids.$2, publication),
    ),
    confirmedAuthoringDocumentProvider.overrideWith((ref, requested) {
      _serve(requested.organizationId, requested.realmId, null);
      _transport.addListener(ref.invalidateSelf);
      ref.onDispose(() => _transport.removeListener(ref.invalidateSelf));
      return _transport.observation;
    }),
    realmEditPersistenceProvider.overrideWith(
      (ref, requested) => _serve(
        requested.organizationId,
        requested.realmId,
        _transport.persistence,
      ),
    ),
    authoredResourceCommandsProvider.overrideWith(
      (ref, requested) =>
          _serve(requested.organizationId, requested.realmId, _commands()),
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
    _transport
      ..removeListener(_keepSavedEdits)
      ..dispose();
    await publication.close();
  }
}

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
