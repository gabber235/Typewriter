import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a user who creates an organization lands in it", (tester) async {
    final panel = await tester.pumpPanel([signedIn(ada), userBackend()]);
    final globex = organization("globex");
    panel.world.nats.registerHandler(
      skir.CreateOrganizationRequest(
        name: "globex",
        logoUrl: "",
      ).operation(userId: ada.id).subject,
      (_) => skir.CreateOrganizationResponse.serializer.toBytes(
        skir.CreateOrganizationResponse.createSuccess(
          organization: globex,
          event: skir.UserOrganizationsChanged(
            sequence: 2,
            changes: [skir.UserOrganizationsChange.wrapAdd(globex)],
          ),
        ),
      ),
    );
    await panel.eventually(
      () => expect(panel.field("Enter organization name").exists, isTrue),
    );

    await panel.field("Enter organization name").type("globex");
    await panel.tapOn(find.text("Create"));

    await panel.eventually(
      () => expect(panel.path, startsWith("/organization/globex")),
    );
    expect(
      panel.shows("You do not have access to this organization."),
      isFalse,
    );
  });
}
