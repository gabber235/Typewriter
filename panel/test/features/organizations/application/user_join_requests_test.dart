import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _now = DateTime.utc(2026, 10, 27, 12);

final _yesterday = _now.subtract(const Duration(days: 1));

void main() {
  group("a pending join request", () {
    final cases = {
      "expires in an hour": (
        expiresAt: _now.add(const Duration(hours: 1)),
        remaining: const Duration(hours: 1),
        expired: false,
      ),
      "expired an hour ago": (
        expiresAt: _now.subtract(const Duration(hours: 1)),
        remaining: Duration.zero,
        expired: true,
      ),
      "expires right now": (
        expiresAt: _now,
        remaining: Duration.zero,
        expired: true,
      ),
    };
    for (final MapEntry(key: name, value: expected) in cases.entries) {
      test("that $name has ${expected.remaining} left", () {
        withClock(Clock.fixed(_now), () {
          final request = userJoinRequest(
            "acme",
            requestedAt: _yesterday,
            expiresAt: expected.expiresAt,
          );

          expect(request.remainingDuration, expected.remaining);
          expect(request.isExpired, expected.expired);
        });
      });
    }
  });

  test("cleaning up drops expired requests and keeps the active ones in "
      "order", () async {
    await withClock(Clock.fixed(_now), () async {
      final first = userJoinRequest(
        "first",
        requestedAt: _yesterday,
        expiresAt: _now.add(_day),
      );
      final expired = userJoinRequest(
        "expired",
        requestedAt: _yesterday,
        expiresAt: _now.subtract(_day),
      );
      final last = userJoinRequest(
        "last",
        requestedAt: _yesterday,
        expiresAt: _now.add(_day),
      );
      final world = testWorld([
        signedIn(ada),
        userBackend(joinRequests: [first, expired, last]),
      ]);
      await world.initialized();
      world.watch(userJoinRequestsProvider);
      await world.container.read(userJoinRequestsProvider.future);

      world.container
          .read(userJoinRequestsProvider.notifier)
          .cleanupExpiredRequests();

      expect(world.container.read(userJoinRequestsProvider).value, [
        first,
        last,
      ]);
    });
  });

  group("requesting to join", () {
    final submit = skir.SubmitUserJoinRequestRequest(
      code: skir.recordId("organization_join_code:any"),
    ).operation(userId: ada.id).subject;

    final refusals = {
      "an organization the user already belongs to": (
        skir.SubmitUserJoinRequestResponse.createAlreadyMemberError(),
        409,
        "You are already a member of this organization",
      ),
      "an organization the user already waits on": (
        skir.SubmitUserJoinRequestResponse.createPendingRequestExistsError(),
        409,
        "You already have a pending join request for this organization",
      ),
      "more organizations than the pending limit": (
        skir.SubmitUserJoinRequestResponse.createMaxPendingRequestsError(),
        400,
        "Maximum pending join requests reached",
      ),
      "a code that does not exist": (
        skir.SubmitUserJoinRequestResponse.createCodeNotFoundError(
          code: skir.recordId("organization_join_code:missing"),
        ),
        404,
        "Join code not found or expired",
      ),
    };
    for (final MapEntry(key: name, value: (response, code, message))
        in refusals.entries) {
      test("$name is refused with its reason", () async {
        final world = testWorld([signedIn(ada), userBackend()]);
        world.nats.registerHandler(
          submit,
          (_) =>
              skir.SubmitUserJoinRequestResponse.serializer.toBytes(response),
        );
        await world.initialized();
        world.watch(userJoinRequestsProvider);
        await world.container.read(userJoinRequestsProvider.future);

        await expectLater(
          world.container
              .read(userJoinRequestsProvider.notifier)
              .requestToJoin("missing"),
          throwsA(
            isA<ApiException>()
                .having((error) => error.code, "code", code)
                .having((error) => error.message, "message", message),
          ),
        );
        expect(
          await world.container.read(userJoinRequestsProvider.future),
          isEmpty,
        );
      });
    }

    test("an invite link requests the code at its end and shows the new "
        "request", () async {
      final created = userJoinRequest(
        "acme",
        requestedAt: _yesterday,
        expiresAt: _now.add(_day),
      );
      skir.RecordId? requested;
      final world = testWorld([signedIn(ada), userBackend()]);
      world.nats.registerHandler(submit, (bytes) {
        requested = skir.SubmitUserJoinRequestRequest.serializer
            .fromBytes(bytes)
            .code;
        return skir.SubmitUserJoinRequestResponse.serializer.toBytes(
          skir.SubmitUserJoinRequestResponse.createRequestMade(
            request: created,
            event: skir.UserJoinRequestsChanged(
              sequence: 2,
              changes: [skir.UserJoinRequestsChange.wrapAdd(created)],
            ),
          ),
        );
      });
      await world.initialized();
      world.watch(userJoinRequestsProvider);
      await world.container.read(userJoinRequestsProvider.future);

      await world.container
          .read(userJoinRequestsProvider.notifier)
          .requestToJoin("https://panel.typewritermc.com/join/k3y");

      expect(requested, skir.recordId("organization_join_code:k3y"));
      expect(world.container.read(userJoinRequestsProvider).value, [created]);
    });
  });

  test("cancelling hides the request at once and brings it back when the "
      "server refuses", () async {
    final pending = userJoinRequest(
      "acme",
      requestedAt: _yesterday,
      expiresAt: DateTime.utc(2100),
    );
    final answer = Completer<skir.CancelUserJoinRequestResponse>();
    final world = testWorld([
      signedIn(ada),
      userBackend(joinRequests: [pending]),
    ]);
    world.nats.registerHandler(
      skir.CancelUserJoinRequestRequest(requestId: pending.requestId)
          .operation(userId: ada.id)
          .subject,
      (_) async => skir.CancelUserJoinRequestResponse.serializer.toBytes(
        await answer.future,
      ),
    );
    await world.initialized();
    world.watch(userJoinRequestsProvider);
    await world.container.read(userJoinRequestsProvider.future);

    final cancelling = world.container
        .read(userJoinRequestsProvider.notifier)
        .cancelRequest(pending.requestId);
    await world.container.eventually(
      userJoinRequestsProvider,
      (requests) => requests.value?.isEmpty ?? false,
      description: "the request hidden while the server has not answered",
    );

    answer.complete(
      skir.CancelUserJoinRequestResponse.createRequestNotFoundError(
        requestId: pending.requestId,
      ),
    );
    await expectLater(
      cancelling,
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, "code", 404)
            .having(
              (error) => error.message,
              "message",
              "Join Request not found",
            ),
      ),
    );
    await world.container.eventually(
      userJoinRequestsProvider,
      (requests) => requests.value?.contains(pending) ?? false,
      description: "the refused cancellation restoring the request",
    );
  });
}

const _day = Duration(days: 1);
