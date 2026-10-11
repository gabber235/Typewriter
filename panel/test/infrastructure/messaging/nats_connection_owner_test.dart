import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _firstRealm = skir.recordId("realm_instance:first");
final _secondRealm = skir.recordId("realm_instance:second");
const _permissionSubject = r"$SYS.REQ.USER.INFO";

void main() {
  test(
    "publishes an admitted candidate before closing the previous client",
    () async {
      final fixture = _ConnectionFixture([
        {},
        {_firstRealm},
      ]);
      addTearDown(fixture.close);
      final previous = fixture.owner.client;
      fixture.onReplacement = (client) {
        expect(client, same(fixture.owner.client));
        expect(previous.connectionState, isA<NatsConnected>());
      };

      await fixture.owner.ensureRealmsAdmitted({_firstRealm});

      expect(fixture.published, [fixture.clients.last]);
      expect(previous.connectionState, isA<NatsClosed>());
    },
  );

  test(
    "exact refresh removes extra grants and caches admitted membership",
    () async {
      final fixture = _ConnectionFixture([
        {_firstRealm, _secondRealm},
        {_firstRealm},
      ]);
      addTearDown(fixture.close);
      await fixture.owner.ensureRealmsAdmitted({_firstRealm});
      final previous = fixture.owner.client;

      await fixture.owner.refreshAuthorization({_firstRealm});
      final current = fixture.clients.last;
      expect(fixture.owner.client, same(current));
      expect(previous.connectionState, isA<NatsClosed>());
      final queries = current.requests.length;
      await fixture.owner.refreshAuthorization({_firstRealm});
      expect(current.requests, hasLength(queries));
      expect(fixture.clients, hasLength(2));
    },
  );

  test(
    "interruption invalidates cached grants before the next refresh",
    () async {
      final fixture = _ConnectionFixture([
        {_firstRealm},
        {_firstRealm},
      ]);
      addTearDown(fixture.close);
      await fixture.owner.refreshAuthorization({_firstRealm});
      final previous = fixture.clients.first;
      previous.registerHandler(
        _permissionSubject,
        (_) => previous.permissions({}),
      );
      previous
        ..setConnectionState(const NatsConnecting())
        ..setConnectionState(const NatsConnected());

      await fixture.owner.refreshAuthorization({_firstRealm});

      expect(previous.requests, hasLength(2));
      expect(fixture.owner.client, same(fixture.clients.last));
      expect(previous.connectionState, isA<NatsClosed>());
    },
  );

  test("grant refresh and retry wait for pending admission", () async {
    final fixture = _ConnectionFixture([
      {},
      {_firstRealm, _secondRealm},
      {_firstRealm},
      {_firstRealm},
    ]);
    addTearDown(fixture.close);
    final started = Completer<void>();
    final permissionReply = Completer<Uint8List>();
    fixture.onCreate = (client, index) {
      if (index == 1) {
        client.registerHandler(_permissionSubject, (_) {
          if (!started.isCompleted) started.complete();
          return permissionReply.future;
        });
      }
    };
    final admission = fixture.owner.ensureRealmsAdmitted({
      _firstRealm,
      _secondRealm,
    });
    await started.future;
    final refresh = fixture.owner.refreshAuthorization({_firstRealm});
    final retry = fixture.owner.retry();
    await pumpEventQueue();
    expect(fixture.clients, hasLength(2));
    expect(fixture.published, isEmpty);

    permissionReply.complete(
      fixture.clients[1].permissions({_firstRealm, _secondRealm}),
    );
    await Future.wait([admission, refresh, retry]);

    expect(fixture.clients, hasLength(4));
    expect(fixture.published, fixture.clients.skip(1).toList());
    expect(fixture.owner.client, same(fixture.clients.last));
    expect(
      fixture.clients.take(3).map((client) => client.connectionState),
      everyElement(isA<NatsClosed>()),
    );
  });

  test(
    "closing a pending candidate blocks publication and queued retry",
    () async {
      final fixture = _ConnectionFixture([
        {},
        {_firstRealm},
      ]);
      addTearDown(fixture.close);
      final started = Completer<void>();
      final permissionReply = Completer<Uint8List>();
      fixture.onCreate = (client, index) {
        if (index == 1) {
          client.registerHandler(_permissionSubject, (_) {
            if (!started.isCompleted) started.complete();
            return permissionReply.future;
          });
        }
      };
      final admission = fixture.owner.ensureRealmsAdmitted({_firstRealm});
      final closed = isA<NatsClientException>().having(
        (error) => error.kind,
        "kind",
        NatsFailureKind.closed,
      );
      final admissionFailure = expectLater(admission, throwsA(closed));
      await started.future;
      final retryFailure = expectLater(fixture.owner.retry(), throwsA(closed));

      await fixture.owner.close();
      expect(
        fixture.clients.map((client) => client.connectionState),
        everyElement(isA<NatsClosed>()),
      );
      permissionReply.complete(fixture.clients.last.permissions({_firstRealm}));
      await Future.wait([admissionFailure, retryFailure]);

      expect(fixture.published, isEmpty);
      expect(fixture.clients, hasLength(2));
      await fixture.owner.close();
    },
  );

  test("settings do not print authentication credentials", () {
    expect(
      _ConnectionFixture.settings.toString(),
      isNot(contains("fixture-token")),
    );
    expect(
      _ConnectionFixture.settings.toString(),
      isNot(contains("fixture-seed")),
    );
  });
}

final class _ConnectionFixture {
  _ConnectionFixture(this.grants) {
    owner = NatsConnectionOwner(
      settings: settings,
      clientFactory: _create,
      sessionFactory: () => clients.length.toString().padLeft(32, "0"),
      onReplacement: (client) {
        published.add(client);
        onReplacement?.call(client);
      },
    );
  }

  static final settings = NatsConnectionSettings(
    url: "nats://fixture:4222",
    token: "fixture-token",
    user: const UserInfo(sub: "fixture-user"),
    sentinel: skir.GetSentinelCredentialsResponse_Success(
      jwt: "fixture-jwt",
      seed: "fixture-seed",
    ),
    organization: skir.recordId("organization:fixture"),
  );
  final List<Set<skir.RecordId>> grants;
  final clients = <FakeNatsClient>[];
  final published = <NatsClient>[];
  late final NatsConnectionOwner owner;
  void Function(FakeNatsClient, int)? onCreate;
  void Function(NatsClient)? onReplacement;

  FakeNatsClient _create(NatsClientConfiguration configuration) {
    final client = FakeNatsClient(
      actorId: configuration.actorId,
      organizationId: configuration.organizationId,
      connectionSession: configuration.connectionSession,
    );
    final index = clients.length;
    client.registerHandler(
      _permissionSubject,
      (_) => client.permissions(grants[index]),
    );
    clients.add(client);
    onCreate?.call(client, index);
    return client;
  }

  Future<void> close() async {
    await owner.close();
    await Future.wait(clients.map((client) => client.close()));
  }
}

extension on FakeNatsClient {
  Uint8List permissions(Set<skir.RecordId> realms) {
    final grant = panelTransportPermissions(
      actorId: actorId,
      organizationId: skir.recordId("organization:${this.organizationId}"),
      connectionSession: connectionSession,
      realmIds: realms,
    );
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          "data": {
            "permissions": {
              "publish": {"allow": grant.publish.toList()},
              "subscribe": {"allow": grant.subscribe.toList()},
            },
          },
        }),
      ),
    );
  }
}
