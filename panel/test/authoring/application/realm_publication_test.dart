import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("a new view hint immediately revokes the old command and only a "
      "coherent ready review authorizes publishing", () async {
    final world = await signedInWorld([
      signedIn(ada, organization: acme),
      realm(),
    ]);
    world.container.listen(world.realmPublication, (_, _) {});
    final repository = world.requireRealm.publication
      ..emit(readyPublicationStatus())
      ..send = () async =>
          SubmissionConfirmed(skir.PublishAuthoringResponse.noChanges);
    final stale =
        (await world.publicationView<ReadyRealmPublication>()).command;

    repository.observe(
      PublicationObservation.fetching(skir.PublicationViewId(value: "new")),
    );
    await world.publicationView<CheckingRealmPublication>();

    expect(
      await stale.invoke(),
      isA<skir.PublishAuthoringResponse_candidateChangedErrorWrapper>(),
    );
    expect(repository.candidates, isEmpty);

    final blocked = blockedPublicationStatus();
    repository.emit(blocked);
    await world.publicationView<BlockedRealmPublication>(review: blocked);

    final ready = readyPublicationStatus(candidate: "new");
    repository.emit(ready, id: "new");
    final fresh = await world.publicationView<ReadyRealmPublication>(
      review: ready,
    );
    await fresh.command.invoke();

    expect(repository.candidates.single.value, "new");
    await world.publicationView<ReadyRealmPublication>();
  });

  test("repeated invocation and old terminal observations cannot authorize "
      "a second request while sending", () async {
    final world = await signedInWorld([
      signedIn(ada, organization: acme),
      realm(),
    ]);
    world.container.listen(world.realmPublication, (_, _) {});
    final response =
        Completer<SubmissionResult<skir.PublishAuthoringResponse>>();
    final repository = world.requireRealm.publication
      ..emit(readyPublicationStatus())
      ..send = () => response.future;
    final command =
        (await world.publicationView<ReadyRealmPublication>()).command;
    final first = command.invoke();
    await eventually(() => expect(repository.candidates, isNotEmpty));

    final oldStatus = readyPublicationStatus(candidate: "older");
    repository.emit(oldStatus, id: "old");
    await world.publicationView<RequestActiveRealmPublication>(
      review: oldStatus,
    );
    expect(
      await command.invoke(),
      isA<skir.PublishAuthoringResponse_candidateChangedErrorWrapper>(),
    );
    expect(repository.candidates, hasLength(1));

    response.complete(
      SubmissionConfirmed(skir.PublishAuthoringResponse.noChanges),
    );
    await first;
    await world.publicationView<ReadyRealmPublication>();
  });

  test("unknown delivery remains readonly after coherent observations and "
      "never offers replay", () async {
    final world = await signedInWorld([
      signedIn(ada, organization: acme),
      realm(),
    ]);
    world.container.listen(world.realmPublication, (_, _) {});
    final repository = world.requireRealm.publication
      ..emit(readyPublicationStatus())
      ..send = () async => SubmissionUncertain(
        message: "Reply missing",
        cause: TimeoutException("timeout"),
        stackTrace: StackTrace.current,
      );
    final command =
        (await world.publicationView<ReadyRealmPublication>()).command;

    await expectLater(
      command.invoke(),
      throwsA(isA<SubmissionException<skir.PublishAuthoringResponse>>()),
    );
    final later = readyPublicationStatus(candidate: "later");
    repository.emit(later);

    await world.publicationView<UncertainRealmPublication>(review: later);
    final entry = world.workEntry("publication");
    expect(entry.needsAttention, isTrue);
    expect(entry.saving, isFalse);
    expect(entry.blocksNavigation, isFalse);
    expect(entry.canRetry || entry.canSave || entry.canDiscard, isFalse);
    expect(
      world.container.read(localWorkProvider.notifier).submissions.single,
      isA<MutationSubmission<Object?>>().having(
        (submission) => submission.canReplay,
        "can replay",
        isFalse,
      ),
    );
    expect(
      await command.invoke(),
      isA<skir.PublishAuthoringResponse_candidateChangedErrorWrapper>(),
    );
    expect(repository.candidates, hasLength(1));
  });

  test("a publication keeps sending after its view closed and shows "
      "publishing when reopened", () async {
    final world = await signedInWorld([
      signedIn(ada, organization: acme),
      realm(),
    ]);
    final gate = Completer<void>();
    final repository = world.requireRealm.publication
      ..emit(readyPublicationStatus())
      ..send = () async {
        await gate.future;
        return SubmissionConfirmed(skir.PublishAuthoringResponse.publishing);
      };
    final view = world.container.listen(world.realmPublication, (_, _) {});
    final publishing = (await world.publicationView<ReadyRealmPublication>())
        .command
        .invoke();
    await eventually(() => expect(repository.candidates, isNotEmpty));
    expect(world.workEntry("publication").saving, isTrue);
    expect(world.workEntry("publication").needsAttention, isFalse);

    view.close();
    repository.emit(publishingPublicationStatus());
    gate.complete();

    expect(await publishing, skir.PublishAuthoringResponse.publishing);
    world.container.listen(world.realmPublication, (_, _) {});
    await world.publicationView<PublishingRealmPublication>();
    expect(world.workEntry("publication").phase, "Publishing saved content");
    expect(repository.candidates, hasLength(1));
    expect(world.container.read(localWorkProvider).blocksNavigation, isFalse);
  });

  test("publishing saved content leaves a pending rename and its work "
      "intact", () async {
    final world = await signedInWorld([
      signedIn(ada, organization: acme),
      realm(books: [book("First")]),
    ]);
    world.container.listen(world.realmPublication, (_, _) {});
    final seeded = world.requireRealm;
    final title = authoredFieldLocation(book("First").bookId, ["title"]);
    skir.DataValue? published;
    seeded.publication.send = () async {
      published = seeded.document.valueAt(title);
      return SubmissionConfirmed(skir.PublishAuthoringResponse.publishing);
    };
    seeded.publication.emit(readyPublicationStatus());
    final editing = await world.openRealmEditing();
    editing.setText(
      "Pending rename",
      title,
      "Draft name",
      policy: EditorCommitPolicy.applyResource,
    );

    expect(
      await (await world.publicationView<ReadyRealmPublication>()).command
          .invoke(),
      skir.PublishAuthoringResponse.publishing,
    );

    expect(published, skir.DataValue.wrapStringValue("First"));
    expect(
      editing.document.valueAt(title),
      skir.DataValue.wrapStringValue("Draft name"),
    );
    final work = world.container.read(localWorkProvider);
    expect(
      work.entries.values.map((entry) => entry.label),
      contains("Pending rename"),
    );
    expect(work.blocksNavigation, isTrue);
    expect(world.workEntry("publication").blocksNavigation, isFalse);
  });

  test("default and unknown nested variants never carry a publish "
      "capability", () {
    expect(validPublicationStatus(skir.PublicationStatus.unknown), isFalse);
    expect(
      validPublicationStatus(
        skir.PublicationStatus.wrapReady(
          skir.PublicationStatus_Ready.defaultInstance,
        ),
      ),
      isFalse,
    );
    expect(validPublicationStatus(readyPublicationStatus()), isTrue);
  });

  for (final result in [
    skir.PublishAuthoringResponse.wrapBlockedError(
      skir.PublicationBlockers(
        first: skir.PublicationBlocker(details: publicationProblem()),
        additional: const [],
      ),
    ),
    skir.PublishAuthoringResponse.unknown,
  ]) {
    test("publication transport journals ${result.kind.name} without "
        "inventing replay", () async {
      final world = await signedInWorld([
        signedIn(ada, organization: acme),
        realmPublicationOverNats(),
      ]);
      final repository = world.container.read(
        realmPublicationRepositoryProvider(acme.organizationId, _realmId),
      );
      world.nats.registerHandler(
        "service.to.realm1.organization.acme.realm.editor.authoring.publish",
        (_) => skir.PublishAuthoringResponse.serializer.toBytes(result),
      );
      final work = testWorkSession();
      final commit = repository.preparePublish(
        skir.PublicationCandidateId(value: "reviewed"),
      );

      if (result == skir.PublishAuthoringResponse.unknown) {
        await expectLater(
          work.execute(commit),
          throwsA(isA<SubmissionException<skir.PublishAuthoringResponse>>()),
        );
        expect(
          work.submissions.single.result,
          isA<SubmissionUncertain<skir.PublishAuthoringResponse>>(),
        );
      } else {
        expect(await work.execute(commit), result);
        expect(
          work.submissions.single.result,
          isA<SubmissionRejected<skir.PublishAuthoringResponse>>(),
        );
      }
      expect(commit.replay, SubmissionReplay.unsupported);
      expect(commit.resources, {
        WorkDriverId(
          domain: "publication",
          scope: AuthoringScope(
            organizationId: acme.organizationId,
            realmId: _realmId,
          ),
        ),
      });
      expect(work.submissions.single.canReplay, isFalse);
    });
  }

  test("compiled status query preserves saved roots and selected "
      "membership", () async {
    final world = await signedInWorld([
      signedIn(ada, organization: acme),
      realmPublicationOverNats(),
    ]);
    final repository = world.container.read(
      realmPublicationRepositoryProvider(acme.organizationId, _realmId),
    );
    final root = publicationRoot("saved");
    skir.QueryCompiledResourceStatusRequest? captured;
    world.nats.registerHandler(
      "service.to.realm1.organization.acme.realm.editor.authoring.compiled.status.query",
      (bytes) {
        captured = skir.QueryCompiledResourceStatusRequest.serializer.fromBytes(
          bytes,
        );
        return skir.QueryCompiledResourceStatusResponse.serializer.toBytes(
          skir.QueryCompiledResourceStatusResponse.createSuccess(
            statuses: [
              skir.CompiledResourceStatus(
                root: root,
                state: skir.CompiledResourceState.wrapActive(_publicationId),
              ),
            ],
          ),
        );
      },
    );

    final states = await repository.states(
      skir.CompilationStatusSelection.wrapSuppliedRoots([root]),
    );

    expect(
      captured!.selection,
      isA<skir.CompilationStatusSelection_suppliedRootsWrapper>().having(
        (selection) => selection.value,
        "selected roots",
        [root],
      ),
    );
    expect(states.single.root, root);
    expect(
      states.single.state,
      skir.CompiledResourceState.wrapActive(_publicationId),
    );
    expect(
      () => states.add(skir.CompiledResourceStatus.defaultInstance),
      throwsUnsupportedError,
    );
  });

  test("publication transport fetches a coherent bounded view for each "
      "identity hint", () async {
    final world = await signedInWorld([
      signedIn(ada, organization: acme),
      realmPublicationOverNats(),
    ]);
    final repository = world.container.read(
      realmPublicationRepositoryProvider(acme.organizationId, _realmId),
    );
    var view = skir.PublicationView(
      id: skir.PublicationViewId(value: "first"),
      status: readyPublicationStatus(),
    );
    world.nats
      ..registerHandler(
        "service.to.realm1.organization.acme.realm.editor.authoring.publication.watch",
        (_) => skir.WatchPublicationResponse.serializer.toBytes(
          skir.WatchPublicationResponse.wrapViewChanged(
            skir.PublicationViewChanged(current: view.id),
          ),
        ),
      )
      ..registerHandler(
        "service.to.realm1.organization.acme.realm.editor.authoring.publication.query",
        (bytes) {
          final request = skir.QueryPublicationViewRequest.serializer.fromBytes(
            bytes,
          );
          return skir.QueryPublicationViewResponse.serializer.toBytes(
            request.expected == view.id
                ? skir.QueryPublicationViewResponse.wrapView(view)
                : skir.QueryPublicationViewResponse.wrapViewChangedError(
                    skir.PublicationViewChanged(current: view.id),
                  ),
          );
        },
      );
    final observed = <PublicationObservation>[];
    final subscription = repository.watch().listen(observed.add);
    addTearDown(subscription.cancel);
    await eventually(
      () => expect(observed.lastOrNull, isA<AvailablePublicationObservation>()),
    );
    expect(observed.first, isA<FetchingPublicationObservation>());
    expect((observed.last as AvailablePublicationObservation).view.id, view.id);

    view = skir.PublicationView(
      id: skir.PublicationViewId(value: "second"),
      status: blockedPublicationStatus(),
    );
    world.nats.connection.emitMessageOnSubject(
      "service.from.realm1.organization.acme.realm.editor.authoring.publication.watch",
      skir.PublicationViewChanged.serializer.toBytes(
        skir.PublicationViewChanged(current: view.id),
      ),
    );

    await eventually(
      () => expect(
        observed.whereType<AvailablePublicationObservation>().last.view.id,
        view.id,
      ),
    );
    expect(
      (observed.last as AvailablePublicationObservation).view.status,
      isA<skir.PublicationStatus_blockedWrapper>(),
    );
    expect(observed.whereType<FetchingPublicationObservation>(), hasLength(2));
    expect(
      world.nats.connection.requests.where(
        (request) => request.subject == "service.to.realm1.organization.acme.realm.editor.authoring.publication.query",
      ),
      hasLength(2),
    );
  });
}

final _realmId = skir.recordId("service:realm1");
final _publicationId = skir.PublicationId(value: "publication:1");
