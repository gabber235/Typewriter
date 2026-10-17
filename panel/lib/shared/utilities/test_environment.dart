/// Platform neutral access to the Flutter test runner's environment marker.
///
/// The IO implementation reads the process environment. Web builds use the
/// stub because `dart:io` is unavailable there.
library;

export "package:typewriter_panel/shared/utilities/test_environment_stub.dart"
    if (dart.library.io) "package:typewriter_panel/shared/utilities/test_environment_io.dart";
