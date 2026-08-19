import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";

const _applicationId = "com.typewritermc.panel";
const _brandColor = "#009FFF";
const _productName = "Typewriter";

String _read(String path) => File(path).readAsStringSync();

void main() {
  test("web metadata uses the canonical product identity", () {
    final manifest = jsonDecode(_read("web/manifest.json")) as Map;

    expect(manifest["id"], _applicationId);
    expect(manifest["name"], _productName);
    expect(manifest["short_name"], _productName);
    expect(manifest["background_color"], _brandColor);
    expect(manifest["theme_color"], _brandColor);
    expect(
      _read("web/index.html"),
      contains('apple-mobile-web-app-title" content="$_productName"'),
    );
  });

  test("native metadata uses the canonical product identity", () {
    expect(
      _read("android/app/build.gradle.kts"),
      contains('applicationId = "$_applicationId"'),
    );
    expect(
      _read("android/app/src/main/AndroidManifest.xml"),
      contains('android:label="$_productName"'),
    );

    final iosInfo = _read("ios/Runner/Info.plist");
    expect(iosInfo, contains("<string>$_productName</string>"));
    expect(
      _read("ios/Runner.xcodeproj/project.pbxproj"),
      contains("PRODUCT_BUNDLE_IDENTIFIER = $_applicationId;"),
    );

    final macosInfo = _read("macos/Runner/Configs/AppInfo.xcconfig");
    expect(macosInfo, contains("PRODUCT_NAME = $_productName"));
    expect(macosInfo, contains("PRODUCT_BUNDLE_IDENTIFIER = $_applicationId"));
    expect(
      _read("macos/Runner.xcodeproj/project.pbxproj"),
      contains("INFOPLIST_KEY_CFBundleDisplayName = $_productName;"),
    );

    final windowsResources = _read("windows/runner/Runner.rc");
    expect(windowsResources, contains('"FileDescription", "$_productName"'));
    expect(windowsResources, contains('"ProductName", "$_productName"'));
    expect(
      _read("windows/runner/main.cpp"),
      contains('window.Create(L"$_productName"'),
    );

    expect(
      _read("linux/CMakeLists.txt"),
      contains('set(APPLICATION_ID "$_applicationId")'),
    );
    expect(
      _read("linux/runner/my_application.cc"),
      contains('gtk_window_set_title(window, "$_productName")'),
    );

    final snapcraft = _read("snap/snapcraft.yaml");
    expect(snapcraft, startsWith("name: typewriter-panel\n"));
    expect(snapcraft, contains("title: $_productName"));
    expect(snapcraft, contains("name: $_applicationId"));
    final snapDesktop = _read("snap/gui/typewriter-panel.desktop");
    expect(snapDesktop, contains("Name=$_productName"));
    expect(snapDesktop, contains("StartupWMClass=$_applicationId"));
  });

  test("only the approved Rive files are runtime assets", () {
    final pubspec = _read("pubspec.yaml");
    expect(pubspec, startsWith("name: typewriter_panel\n"));
    expect(pubspec, isNot(contains("    - assets/\n")));

    final declaredRiveAssets = RegExp(
      r"^    - assets/(.+\.riv)$",
      multiLine: true,
    ).allMatches(pubspec).map((match) => match.group(1)).toSet();
    expect(declaredRiveAssets, {
      "cute_robot.riv",
      "game_character.riv",
      "robot_island.riv",
      "tour.riv",
    });
  });
}
