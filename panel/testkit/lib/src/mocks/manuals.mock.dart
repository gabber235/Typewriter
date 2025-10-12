import "dart:async";

import "package:faker/faker.dart";
import "package:pub_semver/pub_semver.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/module.pbenum.dart";
import "package:typewriter_panel/logic/manuals/manuals.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/manuals/modules_popup.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

PlatformTarget generateRandomPlatformTarget() {
  final rng = faker.randomGenerator;
  final versions = generateSequentialVersions(
    rng.integer(8, min: 1),
    start: Version.parse(
      "1.19.0",
    ),
  );
  return PlatformTarget(
    platform: paperPlatform,
    constraints: {
      "minecraft_version": PlatformConstraint.version(
          versions: versions.map((v) => v.canonicalizedVersion).toList()),
    },
  );
}

List<ManualModuleReference> generateRandomManualModuleRefs() {
  final rng = faker.randomGenerator;

  // Always include an engine, then add random extensions
  final moduleIds = <String>["paper"];
  final extensionCount = rng.integer(20, min: 1);

  for (var i = 0; i < extensionCount; i++) {
    moduleIds.add(faker.company.name().snakeCase());
  }

  return moduleIds
      .map(
        (id) => ManualModuleReference(
          moduleId: id,
          name: id.formatted,
          version: generateRandomVersion(),
          type: ModuleType.values.randomOrNull()!,
          dependencies:
              moduleIds.randomSubset(rng.integer(moduleIds.length, min: 0)),
          dependents:
              moduleIds.randomSubset(rng.integer(moduleIds.length, min: 0)),
        ),
      )
      .toList();
}

/// Generate a random Manual.
Manual generateRandomManual() {
  final rng = faker.randomGenerator;
  final platforms = List.generate(
    rng.integer(2, min: 1),
    (_) => generateRandomPlatformTarget(),
  );
  final modules = generateRandomManualModuleRefs();
  return Manual(
    id: faker.guid.guid(),
    name: faker.company.name(),
    platforms: platforms,
    modules: modules,
  );
}

/// Mock notifier for Manuals.
class ManualsMock extends Manuals {
  ManualsMock({
    required this.displayState,
    required this.platformsOutcome,
    required this.modulesOutcome,
  });

  final DisplayState displayState;
  final Outcome platformsOutcome;
  final Outcome modulesOutcome;

  List<Manual>? _cache;

  @override
  FutureOr<List<Manual>> build() {
    return displayState.generate(generateRandomManual);
  }

  Future<List<Manual>> _data() async {
    if (_cache != null) return _cache!;
    try {
      final result = await Future.value(build());
      _cache = result;
      return result;
    } on Exception catch (_) {
      return <Manual>[];
    }
  }

  Future<Manual?> _find(String id) async {
    final list = await _data();
    return list.firstWhere(
      (m) => m.id == id,
      orElse: () => Manual(
        id: id,
        name: "Unknown",
        platforms: const [],
        modules: const [],
      ),
    );
  }

  @override
  Future<ManualOperationResult> changePlatformTargets({
    required String manualId,
    required List<PlatformTarget> proposed,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final found = await _find(manualId);
    if (found == null || found.name == "Unknown") {
      return const ManualOperationResult.failure(
        reason: "not_found",
        details: ["Manual not found"],
      );
    }
    if (platformsOutcome == Outcome.failure) {
      return const ManualOperationResult.failure(
        reason: "invalid_constraints",
        details: ["Proposed platforms/constraints are not compatible"],
      );
    }
    final updated = found.copyWith(platforms: proposed);
    return ManualOperationResult.success(manual: updated);
  }

  @override
  Future<ManualOperationResult> changeModules({
    required String manualId,
    required List<ManualModuleReference> proposed,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final found = await _find(manualId);
    if (found == null || found.name == "Unknown") {
      return const ManualOperationResult.failure(
        reason: "not_found",
        details: ["Manual not found"],
      );
    }
    if (modulesOutcome == Outcome.failure) {
      return const ManualOperationResult.failure(
        reason: "incompatible_modules",
        details: ["Selected modules do not satisfy platform constraints"],
      );
    }
    final updated = found.copyWith(modules: proposed);
    return ManualOperationResult.success(manual: updated);
  }
}

/// Provider overrides for widgetbook use cases.
List<Override> manualsProviderOverrides({
  DisplayState state = DisplayState.loading,
  Outcome? modulesOutcome,
  Outcome? platformsOutcome,
}) =>
    [
      manualsProvider.overrideWith(
        () => ManualsMock(
          displayState: state,
          modulesOutcome: modulesOutcome ?? Outcome.values.randomOrNull()!,
          platformsOutcome: platformsOutcome ?? Outcome.values.randomOrNull()!,
        ),
      ),
    ];

/// Generate info for a single manual module id.
ManualModuleInformation generateRandomManualModuleInfo(String moduleId) {
  final versions = generateSequentialVersions(
    faker.randomGenerator.integer(5, min: 1),
    start: generateRandomVersion(),
  );
  final version = faker.randomGenerator.boolean()
      ? versions.randomOrNull()!
      : versions.last;

  return ManualModuleInformation(
    moduleId: moduleId,
    name: moduleId.formatted,
    description: faker.lorem.sentence(),
    author: faker.person.name(),
    type: ModuleType.values.randomOrNull()!,
    version: version,
    compatibleVersions: versions.map((v) => v.canonicalizedVersion).toList(),
    canBeRemoved: faker.randomGenerator.boolean(),
  );
}

/// Mock for manualModulesInfoProvider; generates random info for proposed module ids.
Future<List<ManualModuleInformation>> manualModulesInfoMock(
  Ref ref,
  String moduleId,
) async {
  final modules = await ref.watch(proposedModulesIdsProvider(moduleId).future);
  return modules.map(generateRandomManualModuleInfo).toList();
}

/// Provider override for manualModulesInfoProvider.
List<Override> manualModulesInfoProviderOverrides() => [
      manualModulesInfoProvider.overrideWith(manualModulesInfoMock),
    ];
