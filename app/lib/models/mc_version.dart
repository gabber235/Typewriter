import "package:collection/collection.dart";

enum McVersion implements Comparable<McVersion> {
  zero("0.0"),
  v1_8("1.8"),
  v1_9("1.9"),
  v1_10("1.10"),
  v1_11("1.11"),
  v1_12("1.12"),
  v1_13("1.13"),
  v1_14("1.14"),
  v1_15("1.15"),
  v1_16("1.16"),
  v1_17("1.17"),
  v1_18("1.18"),
  v1_19("1.19"),
  v1_20("1.20"),
  v1_21("1.21");

  const McVersion(this.id);
  final String id;

  static const latest = v1_21;

  static McVersion? tryParse(String? id) {
    if (id == null) return null;
    return McVersion.values.firstWhereOrNull((e) => id.startsWith(e.id));
  }

  @override
  int compareTo(McVersion other) {
    return index.compareTo(other.index);
  }

  bool operator <(McVersion other) => index < other.index;
  bool operator <=(McVersion other) => index <= other.index;
  bool operator >(McVersion other) => index > other.index;
  bool operator >=(McVersion other) => index >= other.index;
}
