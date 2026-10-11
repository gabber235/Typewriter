import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _userId = "user1";
final _organizationId = skir.recordId("organization:org1");
const _subject = "cloud.to.user.user1.organization.org1.roles.watch";

OrganizationRole _role(String id, {String? name}) => OrganizationRole(
  roleId: skir.recordId("organization_role:$id"),
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

final class _Harness {
  _Harness(this.response) {
    nats.registerHandler(
      _subject,
      (_) => skir.WatchOrganizationRolesResponse.serializer.toBytes(response),
    );
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => _userId),
        organizationIdProvider.overrideWith((ref) => _organizationId),
        natsProvider.overrideWith(() => FakeNats(nats)),
      ],
    );
    subscription = container.listen(
      organizationRolesProvider,
      (previous, next) => value = next,
      fireImmediately: true,
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;
  late final ProviderSubscription<AsyncValue<List<OrganizationRole>>>
  subscription;
  skir.WatchOrganizationRolesResponse response;
  AsyncValue<List<OrganizationRole>> value = const AsyncLoading();

  Future<void> start() => _waitFor(() => value.hasValue || value.hasError);

  Future<void> reload(skir.WatchOrganizationRolesResponse next) async {
    response = next;
    final requestCount = nats.requests.length;
    container.invalidate(organizationRolesProvider);
    await _waitFor(() => nats.requests.length > requestCount && value.hasValue);
  }

  void dispose() {
    subscription.close();
    container.dispose();
    nats.dispose();
  }
}

void main() {
  test("requests the exact role snapshot operation", () async {
    final harness = _Harness(
      skir.WatchOrganizationRolesResponse.wrapList([
        _role("one").toSkir(),
        _role("two").toSkir(),
      ]),
    );
    addTearDown(harness.dispose);
    await harness.start();

    expect(harness.value.requireValue, [_role("one"), _role("two")]);
    expect(harness.nats.requests, hasLength(1));
    final request = harness.nats.requests.single;
    expect(request.subject, _subject);
    expect(
      request.payload,
      skir.WatchOrganizationRolesRequest.serializer.toBytes(
        skir.WatchOrganizationRolesRequest(),
      ),
    );
    expect(harness.nats.subscriptionSubjects, isEmpty);
  });

  test("provider invalidation reloads the authoritative snapshot", () async {
    final harness = _Harness(
      skir.WatchOrganizationRolesResponse.wrapList([_role("one").toSkir()]),
    );
    addTearDown(harness.dispose);
    await harness.start();

    final updated = _role("one", name: "Updated");
    await harness.reload(
      skir.WatchOrganizationRolesResponse.wrapList([updated.toSkir()]),
    );

    expect(harness.value.requireValue, [updated]);
    expect(harness.nats.requests, hasLength(2));
  });

  for (final (name, response, code) in [
    (
      "internal error",
      skir.WatchOrganizationRolesResponse.createInternalError(),
      500,
    ),
    ("unknown response", skir.WatchOrganizationRolesResponse.unknown, 422),
  ]) {
    test("$name yields ApiException", () async {
      final harness = _Harness(response);
      addTearDown(harness.dispose);
      await harness.start();

      expect(
        harness.value.error,
        isA<ApiException>().having((error) => error.code, "code", code),
      );
    });
  }

  test("role change response is rejected at the snapshot boundary", () async {
    final harness = _Harness(
      skir.WatchOrganizationRolesResponse.wrapAdd(_role("one").toSkir()),
    );
    addTearDown(harness.dispose);
    await harness.start();

    expect(harness.value.error, isA<StateError>());
  });
}
