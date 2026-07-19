import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/typewriter_testkit.dart";

const _userId = "user1";
final _organizationId = recordId("organization:org1");
const _publishSubject = "cloud.to.user.user1.organization.org1.roles.watch";
const _listenSubject = "cloud.from.organization.org1.roles.watch";

OrganizationRole _role(String id, {String? name}) => OrganizationRole(
  roleId: recordId("organization_role:$id"),
  name: name ?? "Role $id",
  color: const Color(0xff2196f3),
  assignable: true,
);

Future<void> _waitFor(bool Function() condition) async {
  await Future.doWhile(() async {
    if (condition()) return false;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return true;
  }).timeout(const Duration(seconds: 2));
}

class _Harness {
  _Harness() {
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => _userId),
        organizationIdProvider.overrideWith((ref) => _organizationId),
        natsProvider.overrideWithValue(nats),
      ],
    );
    subscription = container.listen(
      organizationRolesProvider,
      (previous, next) => value = next,
      fireImmediately: true,
    );
  }

  final MockNatsClient nats = MockNatsClient();
  late final ProviderContainer container;
  late final ProviderSubscription<AsyncValue<List<OrganizationRole>>>
  subscription;
  AsyncValue<List<OrganizationRole>> value = const AsyncLoading();

  Future<void> start() => _waitFor(
    () =>
        nats.publications.isNotEmpty &&
        nats.subscriptionSubjects.contains(_listenSubject),
  );

  Future<List<OrganizationRole>> emit(
    skir.WatchOrganizationRolesResponse response,
  ) async {
    final previous = value;
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.WatchOrganizationRolesResponse.serializer.toBytes(response),
    );
    await _waitFor(() => !identical(value, previous));
    return value.requireValue;
  }

  Future<Object> emitError(skir.WatchOrganizationRolesResponse response) async {
    final errorCompleter = Completer<Object>();
    final errorSubscription = container.listen(organizationRolesProvider, (
      previous,
      next,
    ) {
      if (!next.hasError || errorCompleter.isCompleted) return;
      errorCompleter.complete(next.error!);
    });

    try {
      nats.emitMessageOnSubject(
        _listenSubject,
        skir.WatchOrganizationRolesResponse.serializer.toBytes(response),
      );
      return await errorCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TestFailure(
          "Provider did not emit an error within two seconds",
        ),
      );
    } finally {
      errorSubscription.close();
    }
  }

  void dispose() {
    subscription.close();
    container.dispose();
    nats.dispose();
  }
}

void main() {
  late _Harness harness;

  setUp(() async {
    harness = _Harness();
    await harness.start();
  });

  tearDown(() {
    harness.dispose();
  });

  test("publishes serialized request and subscribes to exact subject", () {
    expect(harness.nats.publications, hasLength(1));
    final publication = harness.nats.publications.single;
    expect(publication.subject, _publishSubject);
    expect(publication.replyTo, _listenSubject);
    expect(harness.nats.subscriptionSubjects, contains(_listenSubject));
    expect(
      publication.data,
      skir.WatchOrganizationRolesRequest.serializer.toBytes(
        skir.WatchOrganizationRolesRequest(),
      ),
    );
    expect(
      skir.WatchOrganizationRolesRequest.serializer.fromBytes(publication.data),
      isA<skir.WatchOrganizationRolesRequest>(),
    );
  });

  test("list replaces state", () async {
    await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapAdd(_role("old").toSkir()),
    );
    final roles = await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapList([
        _role("one").toSkir(),
        _role("two").toSkir(),
      ]),
    );
    expect(roles, [_role("one"), _role("two")]);
  });

  test("add appends role", () async {
    await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapList([_role("one").toSkir()]),
    );
    final roles = await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapAdd(_role("two").toSkir()),
    );
    expect(roles, [_role("one"), _role("two")]);
  });

  test("update replaces matching role", () async {
    await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapList([_role("one").toSkir()]),
    );
    final updated = _role("one", name: "Updated");
    final roles = await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapUpdate(updated.toSkir()),
    );
    expect(roles, [updated]);
  });

  test("update appends unknown role", () async {
    await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapList([_role("one").toSkir()]),
    );
    final roles = await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapUpdate(_role("two").toSkir()),
    );
    expect(roles, [_role("one"), _role("two")]);
  });

  test("remove deletes matching role", () async {
    await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapList([
        _role("one").toSkir(),
        _role("two").toSkir(),
      ]),
    );
    final roles = await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapRemove(_role("one").roleId),
    );
    expect(roles, [_role("two")]);
  });

  test("remove before initial list returns empty list", () async {
    final roles = await harness.emit(
      skir.WatchOrganizationRolesResponse.wrapRemove(_role("one").roleId),
    );
    expect(roles, isEmpty);
  });

  test("internal error yields ApiException", () async {
    final error = await harness.emitError(
      skir.WatchOrganizationRolesResponse.createInternalError(),
    );
    expect(
      error,
      isA<ApiException>().having((error) => error.code, "code", 500),
    );
  });

  test("unknown response yields ApiException", () async {
    final error = await harness.emitError(
      skir.WatchOrganizationRolesResponse.unknown,
    );
    expect(
      error,
      isA<ApiException>().having((error) => error.code, "code", 422),
    );
  });
}
