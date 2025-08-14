import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:mocktail/mocktail.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/module_version/module_version.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/utils/collection.dart";

/// Mock states representing typical loading/data/error scenarios.
enum MockModulesState { loading, noModules, fewModules, manyModules, error }

/// Generate a sequential list of ModuleVersion objects starting at 0.0.1
List<ModuleVersion> generateSequentialVersions(int count) {
  if (count <= 0) return <ModuleVersion>[];
  final rng = faker.randomGenerator;
  final versions = <ModuleVersion>[];

  var current = ModuleVersion.fromParts(patch: 1).copyWith(
    state:
        count == 1
            ? ModuleVersionState.developing
            : ModuleVersionState.published,
  );
  versions.add(current);

  for (var i = 1; i < count; i++) {
    final p = rng.decimal(); // 0 <= p < 1
    if (p < 0.50) {
      current = current.bumpPatch();
    } else if (p < 0.93) {
      current = current.bumpMinor();
    } else if (p < 0.99) {
      current = current.bumpMajor();
    } else {
      current = current.bumpEpoch();
    }

    final stateRoll = rng.decimal();
    ModuleVersionState state;
    final isLast = i == count - 1;
    if (isLast) {
      state =
          stateRoll < 0.4
              ? ModuleVersionState.developing
              : ModuleVersionState.published;
    } else {
      if (stateRoll < 0.10) {
        state = ModuleVersionState.developing;
      } else if (stateRoll < 0.15) {
        state = ModuleVersionState.yoinked;
      } else {
        state = ModuleVersionState.published;
      }
    }
    current = current.copyWith(state: state);
    versions.add(current);
  }

  return versions;
}

Module generateRandomModule() {
  final name = faker.company.name();
  final kind = ModuleKind.values.randomOrNull()!;
  final versionCount = faker.randomGenerator.integer(100, min: 1);
  final versions = generateSequentialVersions(versionCount);

  return Module(
    id: faker.guid.guid(),
    name: name,
    kind: kind,
    versions: versions,
  );
}

List<Module> generateModules(int count) =>
    List.generate(count, (_) => generateRandomModule());

ModulesMock createModulesMockForState(MockModulesState state) {
  final mock = ModulesMock();
  when(mock.build).thenAnswer(
    (_) => switch (state) {
      MockModulesState.loading => Future.delayed(
        Duration(days: 100000),
        () => <Module>[],
      ),
      MockModulesState.noModules => Future.value(<Module>[]),
      MockModulesState.fewModules => Future.value(generateModules(6)),
      MockModulesState.manyModules => Future.value(generateModules(80)),
      MockModulesState.error => Future.error(
        Exception("Failed to load modules"),
      ),
    },
  );
  when(
    () => mock.changeVersionState(any(), any(), any()),
  ).thenAnswer((_) => Future.delayed(3.seconds, () => null));
  return mock;
}

/// Provider overrides for widgetbook use cases.
List<Override> modulesProviderOverrides({
  MockModulesState state = MockModulesState.loading,
}) => [modulesProvider.overrideWith(() => createModulesMockForState(state))];
