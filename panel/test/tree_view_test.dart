import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/utils/tree_view/tree_view.dart";

class Pair {
  const Pair(this.path, this.value);
  final String path;
  final int value;
}

void main() {
  test(
      "When one element is given expect there to be one inner node with one leaf",
      () {
    final node = createTreeNode(
      [const Pair("some.simple.path", 1)],
      (e) => e.path,
    );
    expect(node.children, hasLength(1));
    expect(node.children.first, isA<InnerTreeNode<Pair>>());

    final innerNode = node.children.first as InnerTreeNode<Pair>;
    expect(innerNode.name, equals("some.simple.path"));
    expect(innerNode.path, equals("some.simple.path"));
    expect(innerNode.children, hasLength(1));
    expect(innerNode.children.first, isA<LeafTreeNode<Pair>>());

    final leafNode = innerNode.children.first as LeafTreeNode<Pair>;
    expect(leafNode.value.value, equals(1));
  });

  test(
      "When two elements are given with empty path expect there to be two leaf nodes",
      () {
    final node = createTreeNode(
      [const Pair("", 1), const Pair("", 2)],
      (e) => e.path,
    );

    expect(node.children, hasLength(2));
    expect(node.children.first, isA<LeafTreeNode<Pair>>());
    expect(node.children.last, isA<LeafTreeNode<Pair>>());

    final leafNode1 = node.children.first as LeafTreeNode<Pair>;
    expect(leafNode1.value.value, equals(1));

    final leafNode2 = node.children.last as LeafTreeNode<Pair>;
    expect(leafNode2.value.value, equals(2));
  });

  test(
      "When two elements with the same path are given expect there to be one inner node with two leaves",
      () {
    final node = createTreeNode(
      [const Pair("some.simple.path", 1), const Pair("some.simple.path", 2)],
      (e) => e.path,
    );
    expect(node.children, hasLength(1));
    expect(node.children.first, isA<InnerTreeNode<Pair>>());

    final innerNode = node.children.first as InnerTreeNode<Pair>;
    expect(innerNode.name, equals("some.simple.path"));
    expect(innerNode.path, equals("some.simple.path"));
    expect(innerNode.children, hasLength(2));
    expect(innerNode.children.first, isA<LeafTreeNode<Pair>>());
    expect(innerNode.children.last, isA<LeafTreeNode<Pair>>());

    final leafNode1 = innerNode.children.first as LeafTreeNode<Pair>;
    expect(leafNode1.value.value, equals(1));

    final leafNode2 = innerNode.children.last as LeafTreeNode<Pair>;
    expect(leafNode2.value.value, equals(2));
  });

  test(
      "When two elements with different paths are given expect there to be one inner node with no name and two inner nodes with each one leave",
      () {
    final node = createTreeNode(
      [const Pair("simple.path", 1), const Pair("other.path", 2)],
      (e) => e.path,
    );
    expect(node.children, hasLength(2));
    expect(node.children.first, isA<InnerTreeNode<Pair>>());
    expect(node.children.last, isA<InnerTreeNode<Pair>>());

    final innerNode1 = node.children.first as InnerTreeNode<Pair>;
    expect(innerNode1.name, equals("simple.path"));
    expect(innerNode1.path, equals("simple.path"));
    expect(innerNode1.children, hasLength(1));
    expect(innerNode1.children.first, isA<LeafTreeNode<Pair>>());

    final leafNode1 = innerNode1.children.first as LeafTreeNode<Pair>;
    expect(leafNode1.value.value, equals(1));

    final innerNode2 = node.children.last as InnerTreeNode<Pair>;
    expect(innerNode2.name, equals("other.path"));
    expect(innerNode2.path, equals("other.path"));
    expect(innerNode2.children, hasLength(1));
    expect(innerNode2.children.first, isA<LeafTreeNode<Pair>>());

    final leafNode2 = innerNode2.children.first as LeafTreeNode<Pair>;
    expect(leafNode2.value.value, equals(2));
  });

  test(
      "When two elements with partially same paths are given expect there to be one inner node with two inner nodes with one leave",
      () {
    final node = createTreeNode(
      [const Pair("some.simple.path", 1), const Pair("some.other.path", 2)],
      (e) => e.path,
    );
    expect(node.children, hasLength(1));
    expect(node.children.first, isA<InnerTreeNode<Pair>>());

    final innerNode = node.children.first as InnerTreeNode<Pair>;

    expect(innerNode.name, equals("some"));
    expect(innerNode.path, equals("some"));
    expect(innerNode.children, hasLength(2));
    expect(innerNode.children.first, isA<InnerTreeNode<Pair>>());
    expect(innerNode.children.last, isA<InnerTreeNode<Pair>>());

    final innerNode1 = innerNode.children.first as InnerTreeNode<Pair>;
    expect(innerNode1.name, equals("simple.path"));
    expect(innerNode1.path, equals("some.simple.path"));
    expect(innerNode1.children, hasLength(1));
    expect(innerNode1.children.first, isA<LeafTreeNode<Pair>>());

    final leafNode1 = innerNode1.children.first as LeafTreeNode<Pair>;
    expect(leafNode1.value.value, equals(1));

    final innerNode2 = innerNode.children.last as InnerTreeNode<Pair>;
    expect(innerNode2.name, equals("other.path"));
    expect(innerNode2.path, equals("some.other.path"));
    expect(innerNode2.children, hasLength(1));
    expect(innerNode2.children.first, isA<LeafTreeNode<Pair>>());

    final leafNode2 = innerNode2.children.first as LeafTreeNode<Pair>;
    expect(leafNode2.value.value, equals(2));
  });

  test(
      "When two elements with one having a sub path of the other expect there to be one inner node with leaf and inner node with a leaf",
      () {
    final node = createTreeNode(
      [
        const Pair("some.simple.path", 1),
        const Pair("some.simple.path.other", 2),
      ],
      (e) => e.path,
    );

    expect(node.children, hasLength(1));
    expect(node.children.first, isA<InnerTreeNode<Pair>>());

    final innerNode = node.children.first as InnerTreeNode<Pair>;

    expect(innerNode.name, equals("some.simple.path"));
    expect(innerNode.path, equals("some.simple.path"));
    expect(innerNode.children, hasLength(2));
    expect(innerNode.children.first, isA<LeafTreeNode<Pair>>());
    expect(innerNode.children.last, isA<InnerTreeNode<Pair>>());

    final leafNode1 = innerNode.children.first as LeafTreeNode<Pair>;
    expect(leafNode1.value.value, equals(1));

    final innerNode2 = innerNode.children.last as InnerTreeNode<Pair>;
    expect(innerNode2.name, equals("other"));
    expect(innerNode2.path, equals("some.simple.path.other"));
    expect(innerNode2.children, hasLength(1));
    expect(innerNode2.children.first, isA<LeafTreeNode<Pair>>());

    final leafNode2 = innerNode2.children.first as LeafTreeNode<Pair>;
    expect(leafNode2.value.value, equals(2));
  });

  test(
      "When two elements with one having a sub path after the other expect there to be one inner node with leaf and inner node with a leaf",
      () {
    final node = createTreeNode(
      [
        const Pair("some.simple.path.other", 2),
        const Pair("some.simple.path", 1),
      ],
      (e) => e.path,
    );

    expect(node.children, hasLength(1));
    expect(node.children.first, isA<InnerTreeNode<Pair>>());

    final innerNode = node.children.first as InnerTreeNode<Pair>;

    expect(innerNode.name, equals("some.simple.path"));
    expect(innerNode.path, equals("some.simple.path"));
    expect(innerNode.children, hasLength(2));
    expect(innerNode.children.first, isA<InnerTreeNode<Pair>>());
    expect(innerNode.children.last, isA<LeafTreeNode<Pair>>());

    final leafNode1 = innerNode.children.last as LeafTreeNode<Pair>;
    expect(leafNode1.value.value, equals(1));

    final innerNode2 = innerNode.children.first as InnerTreeNode<Pair>;
    expect(innerNode2.name, equals("other"));
    expect(innerNode2.path, equals("some.simple.path.other"));
    expect(innerNode2.children, hasLength(1));
    expect(innerNode2.children.first, isA<LeafTreeNode<Pair>>());

    final leafNode2 = innerNode2.children.first as LeafTreeNode<Pair>;
    expect(leafNode2.value.value, equals(2));
  });
}
