import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test("permission snapshot owns caller sets", () {
    final publish = <String>{"publish.exact"};
    final subscribe = <String>{"subscribe.exact"};

    final snapshot = ServerPermissionSnapshot(
      publish: publish,
      subscribe: subscribe,
    );
    publish.clear();
    subscribe.clear();

    expect(snapshot.publish, {"publish.exact"});
    expect(snapshot.subscribe, {"subscribe.exact"});
    expect(snapshot.publish.clear, throwsUnsupportedError);
    expect(snapshot.subscribe.clear, throwsUnsupportedError);
  });

  test("native user info returns exact finite permissions", () async {
    final client = FakeNatsClient();
    addTearDown(client.close);
    client.registerHandler(r"$SYS.REQ.USER.INFO", (_) {
      return Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            "data": {
              "permissions": {
                "publish": {
                  "allow": ["publish.exact", "transfer.*"],
                },
                "subscribe": {
                  "allow": ["subscribe.exact", "_INBOX.fixture.*"],
                },
              },
            },
          }),
        ),
      );
    });

    final snapshot = await client.queryPermissions();

    expect(snapshot.publish, {"publish.exact", "transfer.*"});
    expect(snapshot.subscribe, {"subscribe.exact", "_INBOX.fixture.*"});
    expect(client.requests.single.subject, r"$SYS.REQ.USER.INFO");
  });

  test("recursive permission subjects are rejected", () {
    final payload = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          "data": {
            "permissions": {
              "publish": {
                "allow": ["publish.>"],
              },
              "subscribe": {"allow": <String>[]},
            },
          },
        }),
      ),
    );

    expect(
      () => payload.decodeServerApiResponse().readPermissions(),
      throwsA(isA<FormatException>()),
    );
  });

  test("explicit denies are rejected", () {
    final payload = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          "data": {
            "permissions": {
              "publish": {
                "allow": ["publish.exact"],
                "deny": ["publish.denied"],
              },
              "subscribe": {"allow": <String>[]},
            },
          },
        }),
      ),
    );

    expect(
      () => payload.decodeServerApiResponse().readPermissions(),
      throwsA(isA<FormatException>()),
    );
  });

  test("native server authorization errors retain a safe category", () {
    final payload = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          "error": {"code": 403, "description": "private detail"},
        }),
      ),
    );

    expect(
      payload.decodeServerApiResponse,
      throwsA(
        isA<NatsClientException>()
            .having((error) => error.kind, "kind", NatsFailureKind.permission)
            .having(
              (error) => error.toString(),
              "safe text",
              isNot(contains("private detail")),
            ),
      ),
    );
  });

  test("generated Realm admission discovers only complete concrete grants", () {
    final first = skir.recordId("realm_instance:first");
    final second = skir.recordId("realm_instance:second");
    final client = FakeNatsClient(
      actorId: "fixture-user",
      organizationId: "fixture-organization",
      connectionSession: "0123456789abcdef0123456789abcdef",
    );
    addTearDown(client.close);
    final grant = panelTransportPermissions(
      actorId: client.actorId,
      organizationId: skir.recordId("organization:fixture-organization"),
      connectionSession: client.connectionSession,
      realmIds: [first, second],
    );
    final complete = ServerPermissionSnapshot(
      publish: grant.publish,
      subscribe: grant.subscribe,
    );

    expect(complete.admittedRealms(client), {first, second});

    final incompletePublish = grant.publish.toSet()
      ..remove(
        "service.to.second.organization.fixture-organization.realm.editor."
        "catalog.fetch",
      );
    final incomplete = ServerPermissionSnapshot(
      publish: incompletePublish,
      subscribe: grant.subscribe,
    );
    expect(incomplete.admittedRealms(client), {first});
  });
}
