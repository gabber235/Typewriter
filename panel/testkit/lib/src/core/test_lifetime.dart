import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// Releases of resources the current test made outside a panel, newest last.
List<FutureOr<void> Function()>? _releases;

/// The world whose disposal ends the current test's resources.
World? _owner;

/// Releases [release] when the current test ends.
///
/// In a widget test that pumped a panel, the release runs when the panel the
/// test pumped last unmounts at the end of the test, so the work it stops
/// (such as a saved feedback timer) is gone before Flutter checks that no
/// timer outlived the widget tree. Otherwise it runs in the test's tear down.
/// Releases run newest first, like tear downs.
void endWithTest(FutureOr<void> Function() release) =>
    _currentReleases().add(release);

/// Makes [world] end the current test's resources when it is disposed,
/// taking them over from any world a previous pump made.
void adoptTestResources(World world) {
  final releases = _currentReleases();
  _owner = world;
  world.addCleanup(() {
    if (identical(_owner, world)) return _releaseAll(releases);
  });
}

List<FutureOr<void> Function()> _currentReleases() {
  if (_releases case final releases?) return releases;
  final releases = _releases = [];
  addTearDown(() {
    _releases = null;
    _owner = null;
    return _releaseAll(releases);
  });
  return releases;
}

Future<void> _releaseAll(List<FutureOr<void> Function()> releases) async {
  while (releases.isNotEmpty) {
    await releases.removeLast()();
  }
}
