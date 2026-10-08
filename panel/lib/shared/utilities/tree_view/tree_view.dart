import "package:typewriter_panel/typewriter_panel.dart";

part "tree_view.freezed.dart";

/// Immutable compressed tree used to present path based data hierarchically.
///
/// A [RootTreeNode] is the collection boundary and has no path. An
/// [InnerTreeNode] stores one or more path segments in [InnerTreeNode.name],
/// its complete dot separated path in [InnerTreeNode.path], and child nodes.
/// A [LeafTreeNode] stores the source value. Children preserve input order;
/// callers that need display ordering must sort them at the presentation
/// boundary.
@freezed
class TreeNode<T> with _$TreeNode {
  /// Creates the pathless collection boundary for a tree.
  const factory TreeNode.root({required List<TreeNode<T>> children}) =
      RootTreeNode;

  /// Creates a compressed path node with nested [children].
  ///
  /// [name] contains the path segment or compressed segment represented by
  /// this node. [path] is its complete path from the root.
  @Assert("name != \"\"", "Name must not be empty.")
  @Assert("path != \"\"", "Path must not be empty.")
  const factory TreeNode.inner({
    required String name,
    required String path,
    required List<TreeNode<T>> children,
  }) = InnerTreeNode;

  /// Creates a leaf containing one source [value].
  const factory TreeNode.leaf({required T value}) = LeafTreeNode;
}

/// Creates a compressed path tree from [elements].
///
/// [pathFetcher] returns a dot separated path for each element. Shared path
/// prefixes become one inner node, and each input element becomes one leaf.
/// Empty paths are valid and produce leaves directly below the root. The
/// resulting structure is independent of insertion order, although sibling
/// order follows construction order and is not a display sorting guarantee.
///
/// For example, `some.simple.path` and `some.other.path.too` share the inner
/// node `some`; the remaining path segments stay compressed until another
/// element requires a split.
RootTreeNode<T> createTreeNode<T>(
  List<T> elements,
  String Function(T) pathFetcher,
) {
  var children = <TreeNode<T>>[];

  for (final element in elements) {
    final path = pathFetcher(element);
    children = _createTreeNode(children, path, element, "");
  }

  return RootTreeNode(children: children);
}

(InnerTreeNode<T> innerNode, String path)? _findOverlappingPath<T>(
  List<TreeNode<T>> elements,
  String path,
) {
  for (final element in elements) {
    if (element is! InnerTreeNode<T>) continue;
    final overlappingPath = _overlappingStartingParts(path, element.name);
    if (overlappingPath.isEmpty) continue;
    return (element, overlappingPath);
  }
  return null;
}

String _overlappingStartingParts(String path, String otherPath) {
  final pathParts = path.split(".");
  final otherPathParts = otherPath.split(".");
  final result = <String>[];
  for (var i = 0; i < min(pathParts.length, otherPathParts.length); i++) {
    if (pathParts[i] != otherPathParts[i]) break;
    result.add(pathParts[i]);
  }
  return result.join(".");
}

List<TreeNode<T>> _createTreeNode<T>(
  List<TreeNode<T>> elements,
  String path,
  T value,
  String currentPath,
) {
  if (path.isEmpty) {
    return _applyModifications(elements, [
      _TreeModification.add(node: TreeNode.leaf(value: value)),
    ]);
  }

  final (overlappingNode, overlappingPath) =
      _findOverlappingPath(elements, path) ?? (null, null);

  if (overlappingNode == null || overlappingPath == null) {
    final newPath = currentPath.join(path);
    return _applyModifications(elements, [
      _TreeModification.add(
        node: TreeNode.inner(
          name: path,
          path: newPath,
          children: _createTreeNode([], "", value, newPath),
        ),
      ),
    ]);
  }

  if (overlappingNode.name == overlappingPath) {
    final remainingPath = path.removePrefixPart(overlappingPath);
    final newPath = currentPath.join(overlappingPath);
    return _applyModifications(elements, [
      _TreeModification.update(
        path: overlappingPath,
        node: TreeNode.inner(
          name: overlappingPath,
          path: newPath,
          children: _createTreeNode(
            overlappingNode.children,
            remainingPath,
            value,
            newPath,
          ),
        ),
      ),
    ]);
  }

  final overlappingRemainingPath = overlappingNode.name.removePrefixPart(
    overlappingPath,
  );
  final newInnerNode = TreeNode.inner(
    name: overlappingRemainingPath,
    path: currentPath.join(overlappingNode.name),
    children: overlappingNode.children,
  );

  final remainingPath = path.removePrefixPart(overlappingPath);
  final newNode = _createTreeNode(
    <TreeNode<T>>[],
    remainingPath,
    value,
    currentPath.join(overlappingPath),
  );

  return _applyModifications(elements, [
    _TreeModification.remove(path: overlappingNode.name),
    _TreeModification.add(
      node: TreeNode.inner(
        name: overlappingPath,
        path: currentPath.join(overlappingPath),
        children: [newInnerNode, ...newNode],
      ),
    ),
  ]);
}

List<TreeNode<T>> _applyModifications<T>(
  List<TreeNode<T>> elements,
  List<_TreeModification<T>> modifications,
) {
  final result = [...elements];
  for (final modification in modifications) {
    if (modification is _TreeRemove<T> || modification is _TreeUpdate<T>) {
      result.removeWhere(
        (element) =>
            element.maybeMap(orElse: () => null, inner: (node) => node.name) ==
            modification.mapOrNull(
              remove: (node) => node.path,
              update: (node) => node.path,
            ),
      );
    }
    if (modification is _TreeAdd<T>) {
      result.add(modification.node);
    }
    if (modification is _TreeUpdate<T>) {
      result.add(modification.node);
    }
  }
  return result;
}

@freezed
class _TreeModification<T> with _$TreeModification {
  const factory _TreeModification.add({required TreeNode<T> node}) = _TreeAdd;

  @Assert("path != \"\"", "Path must not be empty.")
  const factory _TreeModification.update({
    required String path,
    required TreeNode<T> node,
  }) = _TreeUpdate;

  @Assert("path != \"\"", "Path must not be empty.")
  const factory _TreeModification.remove({required String path}) = _TreeRemove;
}

extension on String {
  String removePrefixPart(String part) {
    if (!startsWith(part)) return this;
    if (length == part.length) return "";
    return substring(part.length + 1);
  }
}
