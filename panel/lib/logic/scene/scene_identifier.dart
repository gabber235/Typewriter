class SceneIdentifier {
  const SceneIdentifier(this.id);

  final String id;

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SceneIdentifier && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
