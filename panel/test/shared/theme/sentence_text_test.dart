import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "empty states, page descriptions and error screens read in IBM Plex Sans",
    (tester) async {
      final panel = await tester.pumpPanel(
        [window(const Size(1200, 1400))],
        at: const PanelLocation.component(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                title: "No members",
                description: "Invite someone to get started!",
              ),
              PageHeading(
                title: "Members",
                subtext: "Manage everyone who can access this organization.",
              ),
              SizedBox(
                height: 700,
                child: ErrorScreen(
                  message: "The Typewriter connection was closed.",
                ),
              ),
            ],
          ),
        ),
      );
      for (final sentence in [
        "Invite someone to get started!",
        "Manage everyone who can access this organization.",
        "The Typewriter connection was closed.",
        "Something went wrong, please report this to the Typewriter discord.",
      ]) {
        expect(panel.renderedFont(sentence), "IBMPlexSans", reason: sentence);
      }
      expect(panel.renderedFont("No members"), "Lilex");
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      "a field error reads at 4.5:1 in IBM Plex Sans (${brightness.name})",
      (tester) async {
        final panel = await tester.pumpPanel(
          [if (brightness == Brightness.dark) dark],
          at: const PanelLocation.component(
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  errorText: "Enter a valid email address.",
                ),
              ),
            ),
          ),
        );
        final style = panel.renderedStyle("Enter a valid email address.");
        expect(style.fontFamily, "IBMPlexSans");
        for (final surface in panel.theme.colors.textSurfaces) {
          expect(
            wcagContrast(style.color!, surface),
            greaterThanOrEqualTo(4.5),
            reason: "on $surface",
          );
        }
      },
    );
  }
}
