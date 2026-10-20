import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns one captured invocation through input, confirmation and local admission.
/// Target identity is independent of subsequent changes to global selection.
/// Realm previews are proposals over a captured saved observation and local
/// overlay. Confirmation precedes local staging; selection and route recovery
/// run only after staging succeeds. Navigation, catalog and access changes
/// expire prompts, while invocation and input revisions reject unrelated replies.
final class ResourceOperationRunner {
  ResourceOperationRunner({
    required this.ref,
    required this.context,
    required this.scope,
    required this.workspace,
    required this.commands,
    required this.invocation,
    required this.label,
    this.declaredConfirmation,
    this.canMutate,
  }) : _router = ref.read(appRouterProvider),
       _navigation = ref.read(appRouterProvider).navigationRevision {
    _router.addListener(_cancelExpiredDialog);
    workspace.addListener(_cancelExpiredDialog);
    _commandsLease = ref.listenManual(
      authoredResourceCommandsProvider(scope),
      (_, _) {},
    );
  }

  final WidgetRef ref;
  final BuildContext context;
  final AuthoringScope scope;
  final RealmEditing workspace;
  final AuthoredResourceCommands commands;
  final skir.OperationInvocation invocation;
  final String label;
  final skir.OperationConfirmation? declaredConfirmation;
  final bool Function()? canMutate;
  late final ProviderSubscription<AuthoredResourceCommands> _commandsLease;
  final AppRouter _router;
  final int _navigation;
  bool _closed = false;
  bool _navigating = false;
  bool _mutating = false;
  bool _declarationConfirmed = false;
  ModalRoute<dynamic>? _ownedDialog;

  void _cancelExpiredDialog() {
    if (isCurrent && (!_mutating || mutationAllowed)) return;
    final route = _ownedDialog;
    _ownedDialog = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  Future<T?> _showOwnedDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) async {
    try {
      return await showAdvancedDialog<T>(
        context: context,
        builder: (dialogContext) {
          _ownedDialog = ModalRoute.of(dialogContext);
          return builder(dialogContext);
        },
      );
    } finally {
      _ownedDialog = null;
    }
  }

  bool get isCurrent => !_closed && _locationIsCurrent;

  bool get _locationIsCurrent =>
      ref.context.mounted &&
      context.mounted &&
      !workspace.workspace.closed &&
      workspace.document.generation == invocation.catalog &&
      ref.read(selectedAuthoringScopeProvider) == scope &&
      (_router.navigationRevision == _navigation ||
          _navigating && _router.navigationRevision == _navigation + 1);

  bool get mutationAllowed =>
      isCurrent && workspace.state.available && (canMutate?.call() ?? true);

  Future<void> navigate(
    skir.ResourceId resource,
    skir.ResourceNavigationMode mode,
  ) async {
    if (!isCurrent) return;
    if (declaredConfirmation != null &&
        !_declarationConfirmed &&
        !await _confirm(null)) {
      return;
    }
    if (!isCurrent) return;
    _navigating = true;
    await ref
        .read(realmSurfaceNavigationProvider)
        .navigate(scope, resource, mode, isCurrent: () => _locationIsCurrent);
  }

  Future<void> invokeCommand(
    skir.CapabilityId capability,
    skir.DataValue payload,
  ) async {
    if (!mutationAllowed || !await _confirm(null) || !mutationAllowed) return;
    _mutating = true;
    final result = await commands.invokeCommand(
      capabilityId: capability,
      payload: payload,
    );
    await handleRealmCommandResult(
      result,
      isCurrent: () => isCurrent,
      reload: commands.reload,
      openResource: (resource) =>
          navigate(resource, skir.ResourceNavigationMode.open),
      reportStatus: _showFailure,
    );
  }

  Future<void> reload() async {
    if (!mutationAllowed || !await _confirm(null) || !mutationAllowed) return;
    _mutating = true;
    await commands.reload();
  }

  Future<void> prepare(
    skir.CapabilityId capability,
    List<skir.ResourceId> targets,
    skir.DataValue? initialInput,
  ) async {
    if (!mutationAllowed) return;
    _mutating = true;
    final call = skir.OperationInvocation(
      invocationId: invocation.invocationId,
      catalog: invocation.catalog,
      targets: targets,
      origin: skir.OperationOrigin(
        container: invocation.origin.container,
        occurrences: invocation.origin.occurrences.where(
          (occurrence) =>
              targets.contains(occurrence.target.resource) ||
              targets.contains(occurrence.source),
        ),
      ),
    );
    OperationInputDraft? input;
    final answers = <skir.PreparationChoiceId, skir.PreparationChoiceAnswer>{};
    var choices = <skir.PreparationChoice>[];
    var problems = <skir.OperationInputProblem>[];
    String? retryMessage;
    var revision = 0;
    try {
      final definition = workspace.document.catalog.snapshot.capabilities
          .whereType<skir.CapabilityDefinition_authoringWrapper>()
          .map((item) => item.value)
          .where((item) => item.capabilityId == capability)
          .firstOrNull;
      if (definition == null) {
        throw StateError("The authoring capability is unavailable");
      }
      if (definition.input case final inputDefinition?) {
        final prepared = await commands.prepareValue(
          skir.ValuePreparationRequest(
            catalog: invocation.catalog,
            target: skir.PreparationTarget.wrapValue(inputDefinition.type),
            suppliedValue: initialInput,
          ),
        );
        if (!mutationAllowed) return;
        final value = switch (prepared.content) {
          skir.PreparedContent_valueWrapper(:final value) => value,
          _ => throw StateError(
            "Operation input preparation returned a record",
          ),
        };
        input = OperationInputDraft(
          catalog: workspace.document.catalog,
          type: inputDefinition.type,
          value: value,
        );
      } else if (initialInput != null) {
        throw StateError("This authoring action does not accept input");
      }

      var submit = true;
      while (mutationAllowed) {
        if (!submit) {
          final accepted = await _showInput(
            invocation: call,
            input: input,
            presentation: definition.input?.presentation,
            problems: problems,
            choices: choices,
            answers: answers,
            retryMessage: retryMessage,
          );
          if (!accepted || !mutationAllowed) return;
          revision++;
        }
        submit = false;
        final submittedInput = input?.revision;
        final result = await commands.prepareAuthoringAction(
          skir.PrepareAuthoringActionRequest(
            invocation: call,
            capability: capability,
            context: workspace.captureOperationContext().context,
            inputRevision: revision,
            input: input?.value,
            choices: answers.values,
          ),
        );
        if (!mutationAllowed) return;
        if (input?.revision != submittedInput) continue;
        switch (result) {
          case skir.AuthoringActionResult_needsInputWrapper(:final value):
            _requireResponse(value.invocationId, value.inputRevision, revision);
            if (value.normalizedInput case final normalized?) {
              input?.normalize(normalized, submittedRevision: submittedInput!);
            }
            choices = value.choices.toList();
            problems = value.problems.toList();
            retryMessage = null;
          case skir.AuthoringActionResult_previewWrapper(:final value):
            _requireResponse(value.invocationId, value.inputRevision, revision);
            final confirmationRevision = input?.revision;
            if (!await _confirm(value.confirmation)) return;
            if (!mutationAllowed || input?.revision != confirmationRevision) {
              continue;
            }
            final before = workspace.document;
            final group = workspace.workspace.createGroup(
              label: label,
              lifetime: EditGroupLifetime.operation,
              commits: EditCommitAdmission.requiredDependencies,
            );
            final staged = workspace.stagePrepared(
              group: group,
              label: label,
              edit: value.edit,
            );
            if (staged is EditStaged) {
              _applySelection(value.selection);
              _navigating = true;
              await ref
                  .read(realmSurfaceNavigationProvider)
                  .recoverRemovedRoute(
                    scope,
                    before,
                    workspace.document,
                    isCurrent: () => isCurrent,
                  );
              return;
            }
            workspace.disposeEmptyGroup(group);
            retryMessage = staged is EditStageRejected
                ? staged.message
                : "The operation made no changes";
          case skir.AuthoringActionResult_staleObservationWrapper():
            await workspace.refreshConfirmed();
            answers.clear();
            choices = [];
            retryMessage =
                "Saved resources changed. Review the input and retry";
          default:
            await _showFailure(_failure(result));
            return;
        }
      }
    } on Object catch (error) {
      if (isCurrent) await _showFailure(error.toString());
    } finally {
      input?.dispose();
    }
  }

  void _requireResponse(skir.InvocationId id, int received, int submitted) {
    if (id != invocation.invocationId || received != submitted) {
      throw StateError("The operation response belongs to another invocation");
    }
  }

  void _applySelection(skir.OperationSelectionEffect effect) {
    if (!isCurrent) return;
    switch (effect) {
      case skir.OperationSelectionEffect_replaceWrapper(:final value):
        if (value.any((id) => workspace.document.entry(id) == null)) {
          throw StateError(
            "The result selection references an absent resource",
          );
        }
        ref.read(selectionProvider.notifier).selectAll([
          for (final resource in value)
            AuthoringResourceIdentifier.inScope(scope, resource),
        ]);
      case skir.OperationSelectionEffect.unchanged:
        break;
      default:
        throw StateError("The selection effect is unavailable");
    }
  }

  Future<bool> _confirm(skir.OperationConfirmation? computed) async {
    // Realm preparation already combines declared and handler confirmations.
    final warning =
        computed ?? (_declarationConfirmed ? null : declaredConfirmation);
    if (warning == null) return mutationAllowed;
    final confirmed =
        await _showOwnedDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(warning.title),
            content: Text(warning.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(warning.confirmationLabel),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) _declarationConfirmed = true;
    return confirmed;
  }

  Future<bool> _showInput({
    required skir.OperationInvocation invocation,
    required OperationInputDraft? input,
    required skir.PresentationId? presentation,
    required List<skir.OperationInputProblem> problems,
    required List<skir.PreparationChoice> choices,
    required Map<skir.PreparationChoiceId, skir.PreparationChoiceAnswer>
    answers,
    required String? retryMessage,
  }) async {
    final host = input?.createHost(
      presentation: presentation,
      capabilities: PortablePresentationCapabilities(
        watchSearch: (request) async* {
          final revision = input.revision;
          for (var retry = 0; retry < 2 && mutationAllowed; retry++) {
            final scoped =
                (request.toMutable()
                      ..operationContext = skir.OperationSearchContext(
                        invocation: invocation,
                        context: workspace.captureOperationContext().context,
                        inputRevision: revision,
                      ))
                    .toFrozen();
            var stale = false;
            await for (final update in commands.watchSearch(scoped)) {
              if (!mutationAllowed || input.revision != revision) return;
              if (update
                  is skir.RealmPresentationSearchUpdate_staleObservationWrapper) {
                stale = true;
                break;
              }
              yield update;
            }
            if (!stale) return;
            await workspace.refreshConfirmed();
            answers.clear();
          }
          throw StateError(
            "Saved resources changed. Submit to review the operation",
          );
        },
      ),
    );
    try {
      return await _showOwnedDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(label),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      if (retryMessage != null) Text(retryMessage),
                      if (host != null)
                        PortablePresentationRenderer(host: host),
                      for (final problem in problems) Text(problem.message),
                      for (final choice in choices)
                        _choiceControl(choice, answers),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(retryMessage == null ? "Submit" : "Retry"),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      host?.dispose();
    }
  }

  Widget _choiceControl(
    skir.PreparationChoice choice,
    Map<skir.PreparationChoiceId, skir.PreparationChoiceAnswer> answers,
  ) {
    final id = switch (choice) {
      skir.PreparationChoice_sourceWrapper(:final value) => value.choiceId,
      skir.PreparationChoice_counterpartWrapper(:final value) => value.choiceId,
      _ => throw StateError("The operation choice is unavailable"),
    };
    final title = switch (choice) {
      skir.PreparationChoice_sourceWrapper(:final value) => value.label,
      skir.PreparationChoice_counterpartWrapper(:final value) => value.label,
      _ => "Choice",
    };
    final options = switch (choice) {
      skir.PreparationChoice_sourceWrapper(:final value) => {
        for (final candidate in value.candidates)
          skir.PreparationChoiceAnswer.createSource(
            choiceId: id,
            occurrence: candidate.occurrence,
          ): candidate.label,
      },
      skir.PreparationChoice_counterpartWrapper(:final value) => {
        for (final candidate in value.candidates)
          skir.PreparationChoiceAnswer.createCounterpart(
            choiceId: id,
            counterpart: candidate.counterpart,
          ): candidate.label,
      },
      _ => <skir.PreparationChoiceAnswer, String>{},
    };
    if (!options.containsKey(answers[id])) answers.remove(id);
    return DropdownButtonFormField<skir.PreparationChoiceAnswer>(
      initialValue: answers[id],
      decoration: InputDecoration(labelText: title),
      isExpanded: true,
      items: [
        for (final item in options.entries)
          DropdownMenuItem(value: item.key, child: Text(item.value)),
      ],
      onChanged: (answer) {
        if (answer == null) {
          answers.remove(id);
        } else {
          answers[id] = answer;
        }
      },
    );
  }

  String _failure(skir.AuthoringActionResult result) {
    final diagnostics = switch (result) {
      skir.AuthoringActionResult_invalidWrapper(:final value) =>
        value.diagnostics,
      skir.AuthoringActionResult_unavailableWrapper(:final value) =>
        value.diagnostics,
      skir.AuthoringActionResult_permissionDeniedWrapper(:final value) =>
        value.diagnostics,
      skir.AuthoringActionResult_failedWrapper(:final value) =>
        value.diagnostics,
      _ => null,
    };
    return diagnostics == null || diagnostics.isEmpty
        ? "The operation is unavailable. Refresh the Realm and try again"
        : diagnostics.map((item) => item.message).join("\n");
  }

  Future<void> _showFailure(String message) => _showOwnedDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(label),
      content: Text(message),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    ),
  );

  void dispose() {
    _closed = true;
    _cancelExpiredDialog();
    _commandsLease.close();
    _router.removeListener(_cancelExpiredDialog);
    workspace.removeListener(_cancelExpiredDialog);
  }
}
