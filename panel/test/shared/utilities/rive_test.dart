import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/utilities/rive.dart";

void main() {
  testWidgets("RiveAsset renders placeholder during Flutter tests", (
    tester,
  ) async {
    const placeholderKey = Key("rive-placeholder");

    await tester.pumpWidget(
      const MaterialApp(
        home: RiveAsset(
          asset: "assets/cute_robot.riv",
          stateMachineName: "Motion",
          placeholder: SizedBox(key: placeholderKey),
        ),
      ),
    );

    expect(find.byKey(placeholderKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
