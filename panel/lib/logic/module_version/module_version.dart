import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:pub_semver/pub_semver.dart";
import "package:typewriter_panel/utils/collection.dart";

part "module_version.freezed.dart";
part "module_version.g.dart";

/// JSON converter for pub_semver Version.
///
/// Accepts:
/// - "1.2.3"
/// - { "version": "1.2.3" }
/// - { "epoch": 1, "major": 2, "minor": 3, "patch": 4 } → flattens to (epoch*1000+major).minor.patch
class SemverJsonConverter implements JsonConverter<Version, dynamic> {
  const SemverJsonConverter();

  @override
  Version fromJson(dynamic json) {
    if (json is Version) return json;
    if (json is String) return Version.parse(json);

    if (json is Map<String, dynamic>) {
      if (json.containsKey("version") && json["version"] is String) {
        return Version.parse(json["version"] as String);
      }
      final epoch = (json["epoch"] as int?) ?? 0;
      final major = (json["major"] as int?) ?? 0;
      final minor = (json["minor"] as int?) ?? 0;
      final patch = (json["patch"] as int?) ?? 0;
      return Version(epoch * 1000 + major, minor, patch);
    }
    throw FormatException("Unsupported version JSON: $json");
  }

  @override
  dynamic toJson(Version object) => object.canonicalizedVersion;
}

/// Lifecycle state for a module version.
@JsonEnum(fieldRename: FieldRename.snake)
enum ModuleVersionState {
  developing(Colors.blue, canPublish: true, canYoink: true),
  published(Colors.green, canPublish: false, canYoink: true),
  yoinked(Colors.orange, canPublish: true, canYoink: false, isActive: false);

  const ModuleVersionState(
    this.color, {
    required this.canPublish,
    required this.canYoink,
    this.isActive = true,
  });

  final Color color;
  final bool canPublish;
  final bool canYoink;
  final bool isActive;

  ModuleVersionState get next => values[(index + 1) % values.length];
}

/// Represents a module version: semantic version (with implicit epoch) + state.
/// The stored canonical string form is `(epoch*1000 + major).minor.patch`.
@freezed
abstract class ModuleVersion
    with _$ModuleVersion
    implements Comparable<ModuleVersion> {
  const factory ModuleVersion({
    @SemverJsonConverter() required Version version,
    @Default(ModuleVersionState.developing) ModuleVersionState state,
  }) = _ModuleVersion;

  /// Parse a string into a ModuleVersion.
  factory ModuleVersion.parse(
    String input, {
    ModuleVersionState state = ModuleVersionState.developing,
  }) {
    final converter = const SemverJsonConverter();
    final parsed = converter.fromJson(input);
    return ModuleVersion(version: parsed, state: state);
  }

  /// Create from explicit components (epoch + semantic major).
  factory ModuleVersion.fromParts({
    int epoch = 0,
    int major = 0,
    int minor = 0,
    int patch = 0,
    ModuleVersionState? state,
  }) =>
      ModuleVersion(
        version: Version(epoch * 1000 + major, minor, patch),
        state: state ?? ModuleVersionState.developing,
      );
  const ModuleVersion._();

  factory ModuleVersion.fromJson(Map<String, dynamic> json) =>
      _$ModuleVersionFromJson(json);

  /// Epoch portion (folded into the stored major).
  int get epoch => version.major ~/ 1000;

  /// Semantic major within the current epoch.
  int get semanticMajor => version.major % 1000;

  int get minor => version.minor;

  int get patch => version.patch;

  /// Expanded 4-part form: epoch.semanticMajor.minor.patch.
  String get expanded => "$epoch.$semanticMajor.$minor.$patch";

  /// Canonical persisted 3-part form.
  String get canonical => version.canonicalizedVersion;

  /// Display form. The expanded form is used if the epoch is non-zero.
  String get display => epoch == 0 ? canonical : expanded;

  ModuleVersion bumpPatch() => copyWith(
        version: version.nextPatch,
      );

  ModuleVersion bumpMinor() => copyWith(
        version: version.nextMinor,
      );

  ModuleVersion bumpMajor() => copyWith(
        version: version.nextMajor,
      );

  ModuleVersion bumpEpoch() => copyWith(
        version: Version(
          (epoch + 1) * 1000,
          0,
          0,
        ),
      );

  ModuleVersion publish() {
    if (state != ModuleVersionState.developing) return this;
    return copyWith(state: ModuleVersionState.published);
  }

  ModuleVersion yoink() {
    if (state != ModuleVersionState.published) return this;
    return copyWith(state: ModuleVersionState.yoinked);
  }

  @override
  int compareTo(ModuleVersion other) {
    return version.compareTo(other.version);
  }
}

/// Iterable utilities for ModuleVersion collections.
extension ModuleVersionIterableExtension on Iterable<ModuleVersion> {
  ModuleVersion? latestPublished() {
    return where((mv) => mv.state == ModuleVersionState.published)
        .maxByOrNull((mv) => mv.version);
  }
}
