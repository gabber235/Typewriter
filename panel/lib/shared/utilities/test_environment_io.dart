import "dart:io";

bool get isFlutterTest => Platform.environment["FLUTTER_TEST"] == "true";
