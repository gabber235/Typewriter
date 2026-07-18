class GraphIdentifier {
  const GraphIdentifier(this.id);

  final String id;

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
