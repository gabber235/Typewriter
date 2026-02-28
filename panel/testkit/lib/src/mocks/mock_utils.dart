import "package:faker/faker.dart";
import "package:pub_semver/pub_semver.dart";

enum DisplayState {
  loading,
  noItems,
  fewItems,
  manyItems,
  error;

  Future<List<T>> generate<T>(T Function() generator) {
    return switch (this) {
      DisplayState.loading => Future.delayed(
        Duration(days: 100000),
        () => <T>[],
      ),
      DisplayState.noItems => Future.value(<T>[]),
      DisplayState.fewItems => Future.value(
        List.generate(6, (_) => generator()),
      ),
      DisplayState.manyItems => Future.value(
        List.generate(80, (_) => generator()),
      ),
      DisplayState.error => Future.error(Exception("Failed to load items")),
    };
  }

  /// Generate items using a batch generator that receives the count
  /// and returns the full list at once
  Future<List<T>> generateBatch<T>(List<T> Function(int count) generator) {
    return switch (this) {
      DisplayState.loading => Future.delayed(
        Duration(days: 100000),
        () => <T>[],
      ),
      DisplayState.noItems => Future.value(<T>[]),
      DisplayState.fewItems => Future.value(generator(6)),
      DisplayState.manyItems => Future.value(generator(80)),
      DisplayState.error => Future.error(Exception("Failed to load items")),
    };
  }
}

enum Outcome { success, failure }

/// Generate a random semantic version
Version generateRandomVersion() {
  final rng = faker.randomGenerator;
  final major = rng.integer(5, min: 0);
  final minor = rng.integer(31, min: 0);
  final patch = rng.integer(12, min: 0);
  return Version(major, minor, patch);
}

List<Version> generateSequentialVersions(int count, {Version? start}) {
  if (count <= 0) return <Version>[];
  final rng = faker.randomGenerator;
  final versions = <Version>[];

  var current = start ?? Version.parse("0.0.1");
  versions.add(current);

  for (var i = 1; i < count; i++) {
    final p = rng.decimal(); // 0 <= p < 1
    if (p < 0.50) {
      current = current.nextPatch;
    } else if (p < 0.93) {
      current = current.nextMinor;
    } else if (p < 0.99) {
      current = current.nextMajor;
    } else {
      final currentEpoch = current.major ~/ 1000;
      current = Version((currentEpoch + 1) * 1000, 0, 0);
    }

    versions.add(current);
  }

  return versions;
}
