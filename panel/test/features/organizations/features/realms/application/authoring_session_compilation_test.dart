import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/publication.dart";

void main() {
  final scope = AuthoringScope(
    organizationId: skir.recordId("organization:org1"),
    realmId: skir.recordId("service:realm1"),
  );
  test("a new view hint immediately revokes the old command and only a coherent ready review authorizes publishing", () async {
    final work = ScopedWorkSession();
    final source = TestPublicationRepository(scope);
    final driver = PublicationWorkDriver(scope, source, work)..start();
    addTearDown(() async {
      driver.dispose();
      work.dispose();
      await source.close();
    });
    await waitForPublication(() => driver.view is ReadyRealmPublication);
    final stale = (driver.view as ReadyRealmPublication).command;
    source.observe(
      PublicationObservation.fetching(skir.PublicationViewId(value: "new")),
    );
    expect(driver.view, isA<CheckingRealmPublication>());
    expect(
      await stale.invoke(),
      isA<skir.PublicationResult_candidateChangedWrapper>(),
    );
    expect(source.candidates, isEmpty);
    source.emit(blockedPublicationStatus());
    expect(driver.view, isA<BlockedRealmPublication>());
    source.emit(readyPublicationStatus(candidate: "new"), id: "new");
    final fresh = (driver.view as ReadyRealmPublication).command;
    await fresh.invoke();
    expect(source.candidates.single.value, "new");
    await waitForPublication(() => driver.view is ReadyRealmPublication);
  });
  test("repeated invocation and old terminal observations cannot authorize a second request while sending", () async {
    final work = ScopedWorkSession();
    final source = TestPublicationRepository(scope);
    final response =
        Completer<SubmissionResult<skir.PublishAuthoringResponse>>();
    source.send = () => response.future;
    final driver = PublicationWorkDriver(scope, source, work)..start();
    addTearDown(() async {
      driver.dispose();
      work.dispose();
      await source.close();
    });
    await waitForPublication(() => driver.view is ReadyRealmPublication);
    final command = (driver.view as ReadyRealmPublication).command;
    final first = command.invoke();
    await waitForPublication(() => source.candidates.isNotEmpty);
    source.emit(readyPublicationStatus(), id: "old");
    expect(driver.view, isA<RequestActiveRealmPublication>());
    expect(
      await command.invoke(),
      isA<skir.PublicationResult_candidateChangedWrapper>(),
    );
    expect(source.candidates, hasLength(1));
    response.complete(
      SubmissionConfirmed(
        skir.PublishAuthoringResponse.wrapResult(
          skir.PublicationResult.noChanges,
        ),
      ),
    );
    await first;
    await waitForPublication(() => driver.view is ReadyRealmPublication);
  });
  test("unknown delivery remains readonly after coherent observations and never offers replay", () async {
    final work = ScopedWorkSession();
    final source = TestPublicationRepository(scope)
      ..send = () async => SubmissionUncertain(
        message: "Reply missing",
        cause: TimeoutException("timeout"),
        stackTrace: StackTrace.current,
      );
    final driver = PublicationWorkDriver(scope, source, work)..start();
    addTearDown(() async {
      driver.dispose();
      work.dispose();
      await source.close();
    });
    await waitForPublication(() => driver.view is ReadyRealmPublication);
    final command = (driver.view as ReadyRealmPublication).command;
    await expectLater(
      command.invoke(),
      throwsA(isA<SubmissionException<skir.PublishAuthoringResponse>>()),
    );
    source.emit(readyPublicationStatus(candidate: "later"));
    expect(driver.view, isA<UncertainRealmPublication>());
    expect(work.submissions.single.canReplay, isFalse);
    expect(
      await command.invoke(),
      isA<skir.PublicationResult_candidateChangedWrapper>(),
    );
    expect(source.candidates, hasLength(1));
  });
  test(
    "default and unknown nested variants never carry a publish capability",
    () {
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
    },
  );
}
