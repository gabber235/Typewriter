import "package:flutter/material.dart";
import "package:pub_semver/pub_semver.dart";
import "package:typewriter_panel/generated/models/common.pb.dart" as proto;
import "package:typewriter_panel/generated/models/module.pb.dart";
import "package:typewriter_panel/utils/collection.dart";

/// Extension on ModuleVersionState enum to add UI properties and behavior
extension ModuleVersionStateExtension on ModuleVersionState {
  /// Color for this state in the UI
  Color get color => switch (this) {
    ModuleVersionState.MODULE_VERSION_STATE_DEVELOPING => Colors.blue,
    ModuleVersionState.MODULE_VERSION_STATE_PUBLISHED => Colors.green,
    ModuleVersionState.MODULE_VERSION_STATE_YOINKED => Colors.orange,
    _ => throw UnsupportedError("Unknown module version state"),
  };

  /// Whether this state can transition to published
  bool get canPublish => switch (this) {
    ModuleVersionState.MODULE_VERSION_STATE_DEVELOPING => true,
    ModuleVersionState.MODULE_VERSION_STATE_PUBLISHED => false,
    ModuleVersionState.MODULE_VERSION_STATE_YOINKED => true,
    _ => throw UnsupportedError("Unknown module version state"),
  };

  /// Whether this state can transition to yoinked
  bool get canYoink => switch (this) {
    ModuleVersionState.MODULE_VERSION_STATE_DEVELOPING => true,
    ModuleVersionState.MODULE_VERSION_STATE_PUBLISHED => true,
    ModuleVersionState.MODULE_VERSION_STATE_YOINKED => false,
    _ => throw UnsupportedError("Unknown module version state"),
  };

  /// Whether this version is active (not yoinked)
  bool get isActive => switch (this) {
    ModuleVersionState.MODULE_VERSION_STATE_DEVELOPING => true,
    ModuleVersionState.MODULE_VERSION_STATE_PUBLISHED => true,
    ModuleVersionState.MODULE_VERSION_STATE_YOINKED => false,
    _ => throw UnsupportedError("Unknown module version state"),
  };

  /// User-friendly display name for this state
  String get displayName => switch (this) {
    ModuleVersionState.MODULE_VERSION_STATE_DEVELOPING => "Developing",
    ModuleVersionState.MODULE_VERSION_STATE_PUBLISHED => "Published",
    ModuleVersionState.MODULE_VERSION_STATE_YOINKED => "Yoinked",
    _ => throw UnsupportedError("Unknown module version state"),
  };
}

/// Extension on ModuleVersion proto to add computed properties and methods
extension ModuleVersionExtension on ModuleVersion {
  /// Convert version string to pub_semver Version
  Version toVersion() {
    return Version.parse(version);
  }

  /// Epoch portion (folded into the stored major)
  int get epoch {
    final parsed = toVersion();
    return parsed.major ~/ 1000;
  }

  /// Semantic major within the current epoch
  int get semanticMajor {
    final parsed = toVersion();
    return parsed.major % 1000;
  }

  /// Minor version number
  int get minor {
    return toVersion().minor;
  }

  /// Patch version number
  int get patch {
    return toVersion().patch;
  }

  /// Expanded 4-part form: epoch.semanticMajor.minor.patch
  String get expanded => "$epoch.$semanticMajor.$minor.$patch";

  /// Canonical persisted 3-part form
  String get canonical => version;

  /// Display form. The expanded form is used if the epoch is non-zero
  String get display => epoch == 0 ? canonical : expanded;

  /// Create new version with incremented patch
  ModuleVersion bumpPatch() {
    final parsed = toVersion();
    final newVersion = parsed.nextPatch;
    return deepCopy()..version = newVersion.canonicalizedVersion;
  }

  /// Create new version with incremented minor
  ModuleVersion bumpMinor() {
    final parsed = toVersion();
    final newVersion = parsed.nextMinor;
    return deepCopy()..version = newVersion.canonicalizedVersion;
  }

  /// Create new version with incremented major
  ModuleVersion bumpMajor() {
    final parsed = toVersion();
    final newVersion = parsed.nextMajor;
    return deepCopy()..version = newVersion.canonicalizedVersion;
  }

  /// Create new version with incremented epoch
  ModuleVersion bumpEpoch() {
    final newEpoch = epoch + 1;
    final newVersion = Version(newEpoch * 1000, 0, 0);
    return deepCopy()..version = newVersion.canonicalizedVersion;
  }

  /// Compare this version with another
  int compareTo(ModuleVersion other) {
    return toVersion().compareTo(other.toVersion());
  }
}

/// Extension on Iterable\<ModuleVersion> for collection utilities
extension ModuleVersionIterableExtension on Iterable<ModuleVersion> {
  /// Find the latest published version
  ModuleVersion? latestPublished() {
    return where(
      (mv) => mv.state == ModuleVersionState.MODULE_VERSION_STATE_PUBLISHED,
    ).maxByOrNull((mv) => mv.toVersion());
  }
}

/// Extension on String to convert to/from Version
extension VersionStringExtension on String {
  /// Convert string to Version
  Version toVersion() {
    return Version.parse(this);
  }
}

/// Extension on Version to convert to/from string
extension VersionExtension on Version {
  /// Convert Version to string
  String toVersionString() {
    return canonicalizedVersion;
  }
}

/// Extension on proto Version message to convert to/from pub_semver Version
extension ProtoVersionExtension on proto.Version {
  /// Convert proto Version to pub_semver Version
  Version toVersion() {
    return Version.parse(value);
  }
}
