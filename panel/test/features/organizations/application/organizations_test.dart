import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _create = skir.CreateOrganizationRequest(
  name: "any",
  logoUrl: "",
).operation(userId: ada.id).subject;

void main() {
  test("a created organization joins the user's list as soon as the server "
      "confirms it", () async {
    final created = organization("Globex");
    skir.CreateOrganizationRequest? sent;
    final world = testWorld([signedIn(ada, organization: acme), userBackend()]);
    world.nats.registerHandler(_create, (bytes) {
      sent = skir.CreateOrganizationRequest.serializer.fromBytes(bytes);
      return skir.CreateOrganizationResponse.serializer.toBytes(
        skir.CreateOrganizationResponse.createSuccess(
          organization: created,
          event: skir.UserOrganizationsChanged(
            sequence: 2,
            changes: [skir.UserOrganizationsChange.wrapAdd(created)],
          ),
        ),
      );
    });
    await world.initialized();
    world.watch(organizationsProvider);
    expect(await world.container.read(organizationsProvider.future), [acme]);

    final id = await world.container
        .read(organizationsProvider.notifier)
        .createOrganization(name: "globex", logoUrl: "https://logo.test/g");

    expect(id, created.organizationId);
    expect(sent?.name, "globex");
    expect(sent?.logoUrl, "https://logo.test/g");
    expect(world.container.read(organizationsProvider).value, [acme, created]);
  });

  // An internal error leaves it open whether the organization exists, so the
  // mutation layer keeps the attempt for recovery instead of refusing it.
  test("a server failure creating an organization reaches the user as "
      "unconfirmed and leaves the list as it was", () async {
    final world = testWorld([signedIn(ada, organization: acme), userBackend()]);
    world.nats.registerHandler(
      _create,
      (_) => skir.CreateOrganizationResponse.serializer.toBytes(
        skir.CreateOrganizationResponse.createInternalError(),
      ),
    );
    await world.initialized();
    world.watch(organizationsProvider);
    await world.container.read(organizationsProvider.future);

    await expectLater(
      world.container
          .read(organizationsProvider.notifier)
          .createOrganization(name: "globex", logoUrl: ""),
      throwsA(isA<SubmissionException<skir.CreateOrganizationResponse>>()),
    );
    expect(world.container.read(organizationsProvider).value, [acme]);
  });
}
