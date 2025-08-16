import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:mocktail/mocktail.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/module_version/module_version.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// Generate a sequential list of ModuleVersion
List<ModuleVersion> generateSequentialModuleVersions(int count) {
  final rng = faker.randomGenerator;
  return generateSequentialVersions(count).map((version) {
    final stateRoll = rng.decimal();
    final ModuleVersionState state;
    if (stateRoll < 0.10) {
      state = ModuleVersionState.developing;
    } else if (stateRoll < 0.15) {
      state = ModuleVersionState.yoinked;
    } else {
      state = ModuleVersionState.published;
    }
    return ModuleVersion(
      version: version,
      state: state,
    );
  }).toList();
}

Module generateRandomModule() {
  final name = faker.company.name();
  final kind = ModuleType.values.randomOrNull()!;
  final versionCount = faker.randomGenerator.integer(100, min: 1);
  final versions = generateSequentialModuleVersions(versionCount);

  return Module(
    id: faker.guid.guid(),
    name: name,
    type: kind,
    versions: versions,
  );
}

ModulesMock createModulesMockForState(DisplayState state) {
  final mock = ModulesMock();
  when(mock.build).thenAnswer(
    (_) => state.generate(generateRandomModule),
  );
  when(
    () => mock.changeVersionState(any(), any(), any()),
  ).thenAnswer((_) => Future.delayed(3.seconds, () => null));
  return mock;
}

/// Provider overrides for widgetbook use cases.
List<Override> modulesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [modulesProvider.overrideWith(() => createModulesMockForState(state))];
