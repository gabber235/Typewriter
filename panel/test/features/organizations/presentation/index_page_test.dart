import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final submit = skir.SubmitUserJoinRequestRequest(
    code: skir.recordId("organization_join_code:any"),
  ).operation(userId: ada.id).subject;
  final create = skir.CreateOrganizationRequest(
    name: "any",
    logoUrl: "",
  ).operation(userId: ada.id).subject;

  testWidgets("a user waiting on five organizations cannot ask to join "
      "another", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada),
      userBackend(
        joinRequests: [
          for (final name in "abcde".split("")) userJoinRequest(name),
        ],
      ),
    ]);

    await panel.eventually(
      () => expect(semanticsButton("Join").isEnabled, isFalse),
    );
    expect(
      panel.shows(
        "You have reached the maximum of 5 pending requests. Please wait for "
        "approval or cancel an existing request.",
      ),
      isTrue,
    );
  });

  final invalidInvites = {
    "": "Please enter an invite URL or code.",
    "https://panel.typewritermc.com/join/": "Invalid invite URL or code.",
  };
  for (final MapEntry(key: input, value: reason) in invalidInvites.entries) {
    testWidgets("asking to join with \"$input\" is refused before anything is "
        "sent", (tester) async {
      final panel = await tester.pumpPanel([signedIn(ada), userBackend()]);
      await panel.eventually(
        () => expect(semanticsButton("Join").isEnabled, isTrue),
      );

      await panel.field("Invite URL or code").type(input);
      await panel.tapOn(find.text("Join"));

      expect(panel.shows(reason), isTrue);
      expect(panel.world.nats.requestsTo(submit), isEmpty);
    });
  }

  final invalidNames = {
    "ab": "Name must be at least 3 characters long.",
    "_abc": "Name must start with a lowercase letter or number.",
    "abc_": "Name must end with a lowercase letter or number.",
  };
  for (final MapEntry(key: name, value: reason) in invalidNames.entries) {
    testWidgets("an organization named \"$name\" is refused before anything "
        "is sent", (tester) async {
      final panel = await tester.pumpPanel([signedIn(ada), userBackend()]);
      await panel.eventually(
        () => expect(panel.field("Enter organization name").exists, isTrue),
      );

      await panel.field("Enter organization name").type(name);
      await panel.tapOn(find.text("Create"));

      expect(panel.shows(reason), isTrue);
      expect(panel.world.nats.requestsTo(create), isEmpty);
    });
  }
}
