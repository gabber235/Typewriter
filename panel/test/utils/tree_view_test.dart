import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/utils/tree_view/tree_view.dart";

/// Test data class with path and value for tree construction tests.
class Pair {
  const Pair(this.path, this.value);
  final String path;
  final int value;
}

void main() {
  group("createTreeNode", () {
    group("basic construction", () {
      test("single path creates correct nesting", () {
        final node = createTreeNode([const Pair("a.b.c", 1)], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(node.children.first, isA<InnerTreeNode<Pair>>());

        final innerNode = node.children.first as InnerTreeNode<Pair>;
        expect(innerNode.name, equals("a.b.c"));
        expect(innerNode.path, equals("a.b.c"));
        expect(innerNode.children, hasLength(1));
        expect(innerNode.children.first, isA<LeafTreeNode<Pair>>());

        final leafNode = innerNode.children.first as LeafTreeNode<Pair>;
        expect(leafNode.value.value, equals(1));
      });

      test("empty tree when no elements", () {
        final node = createTreeNode<Pair>([], (e) => e.path);

        expect(node.children, isEmpty);
      });

      test("single element with empty path creates direct leaf", () {
        final node = createTreeNode([const Pair("", 1)], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(node.children.first, isA<LeafTreeNode<Pair>>());

        final leafNode = node.children.first as LeafTreeNode<Pair>;
        expect(leafNode.value.value, equals(1));
      });

      test("no-dot paths become direct inner nodes with leaf", () {
        final node = createTreeNode([const Pair("simple", 1)], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(node.children.first, isA<InnerTreeNode<Pair>>());

        final innerNode = node.children.first as InnerTreeNode<Pair>;
        expect(innerNode.name, equals("simple"));
        expect(innerNode.path, equals("simple"));
        expect(innerNode.children, hasLength(1));
        expect(innerNode.children.first, isA<LeafTreeNode<Pair>>());
      });
    });

    group("merging and splitting", () {
      test("two elements with empty path creates two leaves", () {
        final node = createTreeNode([
          const Pair("", 1),
          const Pair("", 2),
        ], (e) => e.path);

        expect(node.children, hasLength(2));
        expect(node.children[0], isA<LeafTreeNode<Pair>>());
        expect(node.children[1], isA<LeafTreeNode<Pair>>());

        final leaf1 = node.children[0] as LeafTreeNode<Pair>;
        final leaf2 = node.children[1] as LeafTreeNode<Pair>;
        expect(leaf1.value.value, equals(1));
        expect(leaf2.value.value, equals(2));
      });

      test("same path creates single inner node with two leaves", () {
        final node = createTreeNode([
          const Pair("some.simple.path", 1),
          const Pair("some.simple.path", 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(node.children.first, isA<InnerTreeNode<Pair>>());

        final innerNode = node.children.first as InnerTreeNode<Pair>;
        expect(innerNode.name, equals("some.simple.path"));
        expect(innerNode.children, hasLength(2));
        expect(innerNode.children[0], isA<LeafTreeNode<Pair>>());
        expect(innerNode.children[1], isA<LeafTreeNode<Pair>>());
      });

      test("different paths creates separate inner nodes", () {
        final node = createTreeNode([
          const Pair("simple.path", 1),
          const Pair("other.path", 2),
        ], (e) => e.path);

        expect(node.children, hasLength(2));
        expect(node.children[0], isA<InnerTreeNode<Pair>>());
        expect(node.children[1], isA<InnerTreeNode<Pair>>());

        final innerNode1 = node.children[0] as InnerTreeNode<Pair>;
        expect(innerNode1.name, equals("simple.path"));

        final innerNode2 = node.children[1] as InnerTreeNode<Pair>;
        expect(innerNode2.name, equals("other.path"));
      });

      test("partial overlap creates shared parent with branches", () {
        final node = createTreeNode([
          const Pair("some.simple.path", 1),
          const Pair("some.other.path", 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(node.children.first, isA<InnerTreeNode<Pair>>());

        final innerNode = node.children.first as InnerTreeNode<Pair>;
        expect(innerNode.name, equals("some"));
        expect(innerNode.path, equals("some"));
        expect(innerNode.children, hasLength(2));
        expect(innerNode.children[0], isA<InnerTreeNode<Pair>>());
        expect(innerNode.children[1], isA<InnerTreeNode<Pair>>());

        final branch1 = innerNode.children[0] as InnerTreeNode<Pair>;
        expect(branch1.name, equals("simple.path"));
        expect(branch1.path, equals("some.simple.path"));

        final branch2 = innerNode.children[1] as InnerTreeNode<Pair>;
        expect(branch2.name, equals("other.path"));
        expect(branch2.path, equals("some.other.path"));
      });

      test("deep prefix merging creates common ancestor", () {
        final node = createTreeNode([
          const Pair("org.project.module.a", 1),
          const Pair("org.project.module.b", 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final root = node.children.first as InnerTreeNode<Pair>;
        expect(root.name, equals("org.project.module"));
        expect(root.path, equals("org.project.module"));
        expect(root.children, hasLength(2));

        final childA = root.children[0] as InnerTreeNode<Pair>;
        final childB = root.children[1] as InnerTreeNode<Pair>;
        expect(childA.name, equals("a"));
        expect(childA.path, equals("org.project.module.a"));
        expect(childB.name, equals("b"));
        expect(childB.path, equals("org.project.module.b"));
      });
    });

    group("sub-path handling", () {
      test("sub-path added after parent creates nested structure", () {
        final node = createTreeNode([
          const Pair("some.simple.path", 1),
          const Pair("some.simple.path.other", 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final innerNode = node.children.first as InnerTreeNode<Pair>;

        expect(innerNode.name, equals("some.simple.path"));
        expect(innerNode.path, equals("some.simple.path"));
        expect(innerNode.children, hasLength(2));

        // First child is leaf for the parent path
        expect(innerNode.children[0], isA<LeafTreeNode<Pair>>());
        final parentLeaf = innerNode.children[0] as LeafTreeNode<Pair>;
        expect(parentLeaf.value.value, equals(1));

        // Second child is inner node for the sub-path
        expect(innerNode.children[1], isA<InnerTreeNode<Pair>>());
        final subNode = innerNode.children[1] as InnerTreeNode<Pair>;
        expect(subNode.name, equals("other"));
        expect(subNode.path, equals("some.simple.path.other"));
      });

      test("parent path added after sub-path creates correct structure", () {
        final node = createTreeNode([
          const Pair("some.simple.path.other", 2),
          const Pair("some.simple.path", 1),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final innerNode = node.children.first as InnerTreeNode<Pair>;

        expect(innerNode.name, equals("some.simple.path"));
        expect(innerNode.path, equals("some.simple.path"));
        expect(innerNode.children, hasLength(2));

        // Order may differ, but both should be present
        final types = innerNode.children.map((c) => c.runtimeType).toList();
        expect(types, containsAll([InnerTreeNode<Pair>, LeafTreeNode<Pair>]));
      });
    });

    group("order invariance", () {
      test("same tree structure regardless of insertion order", () {
        final elements = [
          const Pair("a.b.c", 1),
          const Pair("a.b.d", 2),
          const Pair("a.e", 3),
        ];

        final node1 = createTreeNode(elements, (e) => e.path);
        final node2 = createTreeNode(elements.reversed.toList(), (e) => e.path);

        // Both should have single root "a"
        expect(node1.children, hasLength(1));
        expect(node2.children, hasLength(1));

        final root1 = node1.children.first as InnerTreeNode<Pair>;
        final root2 = node2.children.first as InnerTreeNode<Pair>;

        expect(root1.name, equals("a"));
        expect(root2.name, equals("a"));

        // Both should have 2 children under "a"
        expect(root1.children, hasLength(2));
        expect(root2.children, hasLength(2));
      });
    });

    group("edge cases", () {
      test("multiple elements with varying depths", () {
        final node = createTreeNode([
          const Pair("a", 1),
          const Pair("a.b", 2),
          const Pair("a.b.c", 3),
          const Pair("x.y", 4),
        ], (e) => e.path);

        // Should have 2 top-level nodes: "a" and "x.y"
        expect(node.children, hasLength(2));

        final nodeNames = node.children
            .map((c) => (c as InnerTreeNode<Pair>).name)
            .toSet();
        expect(nodeNames, containsAll(["a", "x.y"]));
      });

      test("deeply nested single path", () {
        final node = createTreeNode([
          const Pair("a.b.c.d.e.f", 1),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final innerNode = node.children.first as InnerTreeNode<Pair>;
        expect(innerNode.name, equals("a.b.c.d.e.f"));
        expect(innerNode.path, equals("a.b.c.d.e.f"));
      });
    });
  });
}
