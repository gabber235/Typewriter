import "package:json_annotation/json_annotation.dart";
import "package:pub_semver/pub_semver.dart";

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
