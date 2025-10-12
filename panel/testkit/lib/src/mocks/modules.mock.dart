import "dart:async";

import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:pub_semver/pub_semver.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/module.pb.dart";
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
      state = ModuleVersionState.MODULE_VERSION_STATE_DEVELOPING;
    } else if (stateRoll < 0.15) {
      state = ModuleVersionState.MODULE_VERSION_STATE_YOINKED;
    } else {
      state = ModuleVersionState.MODULE_VERSION_STATE_PUBLISHED;
    }
    return ModuleVersion()
      ..version = version.canonicalizedVersion
      ..state = state;
  }).toList();
}

Module generateRandomModule() {
  final name = faker.company.name();
  final kind = ModuleType.values.randomOrNull()!;
  final versionCount = faker.randomGenerator.integer(100, min: 1);
  final versions = generateSequentialModuleVersions(versionCount);

  return Module()
    ..id = faker.guid.guid()
    ..name = name
    ..type = kind
    ..versions.addAll(versions);
}

class ModulesMock extends Modules {
  ModulesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<Module>> build() async {
    return displayState.generate(generateRandomModule);
  }

  @override
  Future<void> changeVersionState(
    List<String> moduleIds,
    Version version,
    ModuleVersionState newState,
  ) async {
    await Future.delayed(3.seconds);
  }
}

/// Provider overrides for widgetbook use cases.
List<Override> modulesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [modulesProvider.overrideWith(() => ModulesMock(displayState: state))];
