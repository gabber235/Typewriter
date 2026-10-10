import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const _configurationPath =
    "test/infrastructure/messaging/fixtures/nats_native.conf";

Set<String> _permissions(
  String configuration,
  String publicKey,
  String direction,
) {
  final start = configuration.indexOf('nkey: "$publicKey"');
  if (start == -1) throw StateError("Fixture user is missing");
  final next = configuration.indexOf("\n      {\n        nkey:", start + 1);
  final usersEnd = configuration.indexOf("\n    ]", start + 1);
  final end = next == -1 ? usersEnd : next;
  final block = configuration.substring(start, end);
  final match = RegExp(
    "$direction"
    r":\s*\{\s*allow:\s*\[(.*?)\]",
    dotAll: true,
  ).firstMatch(block);
  if (match == null) throw StateError("Fixture permission scope is missing");
  return RegExp(r'"(?:\\.|[^"\\])*"')
      .allMatches(match.group(1)!)
      .map((match) => jsonDecode(match.group(0)!) as String)
      .toSet();
}

void main() {
  final existingRealm = skir.recordId("realm_instance:fixture-realm");
  final addedRealm = skir.recordId("realm_instance:fixture-added-realm");
  final cases = [
    (
      "current",
      "UD466L6EBCM3YY5HEGHJANNTN4LSKTSUXTH7RILHCKEQMQHTBNLHJJXT",
      "0123456789abcdef0123456789abcdef",
      [existingRealm],
    ),
    (
      "rejected",
      "UDCGKCWUX6N2QOMTZZ3IPEAXESGNGTRAEL2UP6KWWHHC3ZDZWD5JOYZR",
      "11111111111111111111111111111111",
      [existingRealm],
    ),
    (
      "accepted",
      "UBAUTLCPXVP3KHWDKXI63TD2BLFSDTIUCMPWWRH2QWTLHAASWEV6UHZI",
      "22222222222222222222222222222222",
      [existingRealm, addedRealm],
    ),
  ];

  test("native fixture exactly matches generated finite permissions", () {
    final configuration = File(_configurationPath).readAsStringSync();

    for (final fixture in cases) {
      final expected = panelTransportPermissions(
        actorId: "fixture-user",
        organizationId: skir.recordId("organization:fixture-organization"),
        connectionSession: fixture.$3,
        realmIds: fixture.$4,
      );
      expect(
        _permissions(configuration, fixture.$2, "publish"),
        expected.publish,
        reason: "${fixture.$1} publish grants",
      );
      expect(
        _permissions(configuration, fixture.$2, "subscribe"),
        expected.subscribe,
        reason: "${fixture.$1} subscribe grants",
      );
    }

    expect(configuration, isNot(contains('allow: [">"]')));
    expect(
      configuration,
      isNot(
        contains(
          '"cloud.from.organization.'
          'fixture-organization.roles.watch"',
        ),
      ),
    );
  });
}
