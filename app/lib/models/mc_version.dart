class McVersion implements Comparable<McVersion> {
  const McVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static const zero = McVersion(0, 0, 0);
  static const latest = McVersion(1, 21, 10);

  factory McVersion.parse(String source) =>
      McVersion.tryParse(source) ?? latest;

  static McVersion? tryParse(String? source) {
    if (source == null || source.isEmpty) return null;
    final match =
        RegExp(r'(\\d+)\\.(\\d+)(?:\\.(\\d+))?').firstMatch(source.trim());
    if (match == null) return null;
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3) ?? '0');
    return McVersion(major, minor, patch);
  }

  @override
  int compareTo(McVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(McVersion other) => compareTo(other) < 0;

  bool operator >(McVersion other) => compareTo(other) > 0;

  bool operator <=(McVersion other) => compareTo(other) <= 0;

  bool operator >=(McVersion other) => compareTo(other) >= 0;

  @override
  String toString() => '$major.$minor.$patch';

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  bool operator ==(Object other) =>
      other is McVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;
}
