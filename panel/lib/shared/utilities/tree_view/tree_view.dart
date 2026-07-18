import "dart:math";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

part "tree_view.freezed.dart";

@freezed
class TreeNode<T> with _$TreeNode {
  const factory TreeNode.root({
    required List<TreeNode<T>> children,
  }) = RootTreeNode;

  const factory TreeNode.inner({
    required String name,
    required String path,
    required List<TreeNode<T>> children,
  }) = InnerTreeNode;

  const factory TreeNode.leaf({
    required T value,
  }) = LeafTreeNode;
}

/// Creates a tree node from a list of objects with paths.
/// It nests objects to create the most common ancestor between paths.
///
/// Example, Lets say we have the following paths:
/// - some.simple.path
/// - some.other.path
/// - some.other.path.too
///
/// The result will be:
/// - some
///  - simple
///    - path
///  - other.path
///    - too
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
    return _applyModifications(
      elements,
      [_TreeModification.add(node: TreeNode.leaf(value: value))],
    );
  }

  final (overlappingNode, overlappingPath) =
      _findOverlappingPath(elements, path) ?? (null, null);

  // Part does not exist yet, create it
  if (overlappingNode == null || overlappingPath == null) {
    final newPath = currentPath.join(path);
    return _applyModifications(
      elements,
      [
        _TreeModification.add(
          node: TreeNode.inner(
            name: path,
            path: newPath,
            children: _createTreeNode([], "", value, newPath),
          ),
        ),
      ],
    );
  }

  // Full path exists, so we only need to add it to that node
  if (overlappingNode.name == overlappingPath) {
    final remainingPath = path.removePrefixPart(overlappingPath);
    final newPath = currentPath.join(overlappingPath);
    return _applyModifications(
      elements,
      [
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
      ],
    );
  }

  // Part of the path exists, so we need to remove the old node and add a new node with the partial path
  // Then add the original node with the remaining path to the new node
  // And finally add the new node with the new value
  final overlappingRemainingPath =
      overlappingNode.name.removePrefixPart(overlappingPath);
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

  return _applyModifications(
    elements,
    [
      _TreeModification.remove(path: overlappingNode.name),
      _TreeModification.add(
        node: TreeNode.inner(
          name: overlappingPath,
          path: currentPath.join(overlappingPath),
          children: [
            newInnerNode,
            ...newNode,
          ],
        ),
      ),
    ],
  );
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
  const factory _TreeModification.add({
    required TreeNode<T> node,
  }) = _TreeAdd;

  const factory _TreeModification.update({
    required String path,
    required TreeNode<T> node,
  }) = _TreeUpdate;

  const factory _TreeModification.remove({
    required String path,
  }) = _TreeRemove;
}

extension on String {
  String removePrefixPart(String part) {
    if (!startsWith(part)) return this;
    if (length == part.length) return "";
    return substring(part.length + 1);
  }
}
