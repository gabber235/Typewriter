import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _deleteAcme = "Delete Acme? Nothing can bring it back.";

void main() {
  final page = [
    signedIn(ada, organization: acme),
    membership(
      roles: [role("founder"), role("writer")],
      members: [member("Ada"), member("Grace")],
      joinCodes: [joinCode("spring")],
    ),
  ];

  testWidgets("the sidebar opens the settings as its last organization "
      "link", (tester) async {
    final panel = await tester.pumpPanel(page);

    await panel.tapOn(find.text("Settings"));

    await panel.eventually(
      () => expect(panel.path, "/organization/acme/settings"),
    );
    expect(panel.headings, contains("Settings"));
  });

  testWidgets("before deleting, the page counts what goes with the "
      "organization", (tester) async {
    final panel = await tester.pumpPanel(page, at: organizationSettingsPage());

    await panel.eventually(() {
      expect(panel.shows("2 members lose access."), isTrue);
      expect(
        panel.shows(
          "0 services are unbound and keep running, with their "
          "realms.",
        ),
        isTrue,
      );
      expect(panel.shows("1 join code stops working."), isTrue);
      expect(panel.shows("2 roles are removed."), isTrue);
    });
  });

  group("renaming the organization saves the new name for every page", () {
    testWidgets("with the keyboard alone", (tester) async {
      final panel = await tester.pumpPanel(
        page,
        at: organizationSettingsPage(),
      );

      await panel.tabTo("Organization name");
      await panel.field("Organization name").type("acme_studio");

      await panel.eventually(
        () => expect(
          panel.world.organizations.of(ada.id).single.name,
          "acme_studio",
        ),
      );
    });

    testWidgets("with the mouse alone", (tester) async {
      final panel = await tester.pumpPanel(
        page,
        at: organizationSettingsPage(),
      );

      await panel.tapOn(find.bySemanticsLabel("Organization name").last);
      await panel.field("Organization name").type("acme_studio");

      await panel.eventually(
        () => expect(
          panel.world.organizations.of(ada.id).single.name,
          "acme_studio",
        ),
      );
    });
  });

  testWidgets("a name another organization uses is refused under the field "
      "and keeps the typed name", (tester) async {
    final panel = await tester.pumpPanel([
      ...page,
      organizationRefusals(takenNames: {"globex"}),
    ], at: organizationSettingsPage());

    await panel.field("Organization name").type("globex");

    await panel.eventually(
      () => expect(
        panel.shows(
          "Another organization already uses this name. Choose another name.",
        ),
        isTrue,
      ),
    );
    expect(panel.field("Organization name").value, "globex");
    expect(panel.world.organizations.of(ada.id).single.name, "Acme");
  });

  group("rolling a new icon saves it", () {
    testWidgets("with the keyboard alone", (tester) async {
      final panel = await tester.pumpPanel(
        page,
        at: organizationSettingsPage(),
      );

      await panel.activateWithKeyboard(
        find.bySemanticsLabel(RegExp("^Randomize icon")),
      );

      await panel.eventually(
        () => expect(
          panel.world.organizations.of(ada.id).single.logoUrl,
          isNotEmpty,
        ),
      );
    });

    testWidgets("with the mouse alone", (tester) async {
      final panel = await tester.pumpPanel(
        page,
        at: organizationSettingsPage(),
      );

      await panel.tapOn(find.bySemanticsLabel(RegExp("^Randomize icon")));

      await panel.eventually(
        () => expect(
          panel.world.organizations.of(ada.id).single.logoUrl,
          isNotEmpty,
        ),
      );
    });
  });

  group("the founder deletes the organization with a permanent hold and "
      "lands on the organization list", () {
    testWidgets("with the keyboard alone, by holding Delete", (tester) async {
      final panel = await tester.pumpPanel(
        page,
        at: organizationSettingsPage(),
      );

      await panel.tabTo(_deleteAcme);
      await panel.holdKey(LogicalKeyboardKey.delete);

      await panel.eventually(() => expect(panel.path, "/"));
      expect(panel.world.organizations.of(ada.id), isEmpty);
    });

    testWidgets("with the mouse alone, by holding the button", (tester) async {
      final panel = await tester.pumpPanel(
        page,
        at: organizationSettingsPage(),
      );

      await panel.holdButton(_deleteAcme);

      await panel.eventually(() => expect(panel.path, "/"));
      expect(panel.world.organizations.of(ada.id), isEmpty);
    });
  });

  testWidgets("a delete hold let go early deletes nothing", (tester) async {
    final panel = await tester.pumpPanel(page, at: organizationSettingsPage());

    await panel.holdButton(_deleteAcme, share: 0.5);

    expect(panel.path, "/organization/acme/settings");
    expect(panel.world.organizations.of(ada.id), hasLength(1));
  });

  testWidgets("a refused delete keeps the organization and says why at the "
      "button", (tester) async {
    final panel = await tester.pumpPanel([
      ...page,
      organizationRefusals(deleteRefusal: founderRequired),
    ], at: organizationSettingsPage());

    await panel.holdButton(_deleteAcme);

    await panel.eventually(
      () => expect(panel.shows(onlyFounderDeletes), isTrue),
    );
    expect(panel.path, "/organization/acme/settings");
    expect(panel.world.organizations.of(ada.id), hasLength(1));
  });

  testWidgets("someone who did not found the organization cannot start the "
      "delete and reads why", (tester) async {
    final globex = organization("Globex", founder: grace);
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: globex),
      membership(),
    ], at: organizationSettingsPage(globex));

    await panel.eventually(
      () => expect(panel.shows(onlyFounderDeletes), isTrue),
    );
    await panel.holdButton("Delete organization");

    expect(panel.path, "/organization/globex/settings");
    expect(panel.world.organizations.of(ada.id), hasLength(1));
  });
}
