import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("createTreeNode", () {
    group("basic construction", () {
      test("single path creates correct nesting", () {
        final node = createTreeNode([(path: "a.b.c", value: 1)], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(
          node.children.first,
          isA<InnerTreeNode<({String path, int value})>>(),
        );

        final innerNode =
            node.children.first as InnerTreeNode<({String path, int value})>;
        expect(innerNode.name, equals("a.b.c"));
        expect(innerNode.path, equals("a.b.c"));
        expect(innerNode.children, hasLength(1));
        expect(
          innerNode.children.first,
          isA<LeafTreeNode<({String path, int value})>>(),
        );

        final leafNode =
            innerNode.children.first
                as LeafTreeNode<({String path, int value})>;
        expect(leafNode.value.value, equals(1));
      });

      test("empty tree when no elements", () {
        final node = createTreeNode<({String path, int value})>(
          [],
          (e) => e.path,
        );

        expect(node.children, isEmpty);
      });

      test("single element with empty path creates direct leaf", () {
        final node = createTreeNode([(path: "", value: 1)], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(
          node.children.first,
          isA<LeafTreeNode<({String path, int value})>>(),
        );

        final leafNode =
            node.children.first as LeafTreeNode<({String path, int value})>;
        expect(leafNode.value.value, equals(1));
      });

      test("no-dot paths become direct inner nodes with leaf", () {
        final node = createTreeNode([
          (path: "simple", value: 1),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(
          node.children.first,
          isA<InnerTreeNode<({String path, int value})>>(),
        );

        final innerNode =
            node.children.first as InnerTreeNode<({String path, int value})>;
        expect(innerNode.name, equals("simple"));
        expect(innerNode.path, equals("simple"));
        expect(innerNode.children, hasLength(1));
        expect(
          innerNode.children.first,
          isA<LeafTreeNode<({String path, int value})>>(),
        );
      });
    });

    group("merging and splitting", () {
      test("two elements with empty path creates two leaves", () {
        final node = createTreeNode([
          (path: "", value: 1),
          (path: "", value: 2),
        ], (e) => e.path);

        expect(node.children, hasLength(2));
        expect(
          node.children[0],
          isA<LeafTreeNode<({String path, int value})>>(),
        );
        expect(
          node.children[1],
          isA<LeafTreeNode<({String path, int value})>>(),
        );

        final leaf1 =
            node.children[0] as LeafTreeNode<({String path, int value})>;
        final leaf2 =
            node.children[1] as LeafTreeNode<({String path, int value})>;
        expect(leaf1.value.value, equals(1));
        expect(leaf2.value.value, equals(2));
      });

      test("same path creates single inner node with two leaves", () {
        final node = createTreeNode([
          (path: "some.simple.path", value: 1),
          (path: "some.simple.path", value: 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(
          node.children.first,
          isA<InnerTreeNode<({String path, int value})>>(),
        );

        final innerNode =
            node.children.first as InnerTreeNode<({String path, int value})>;
        expect(innerNode.name, equals("some.simple.path"));
        expect(innerNode.children, hasLength(2));
        expect(
          innerNode.children[0],
          isA<LeafTreeNode<({String path, int value})>>(),
        );
        expect(
          innerNode.children[1],
          isA<LeafTreeNode<({String path, int value})>>(),
        );
      });

      test("different paths creates separate inner nodes", () {
        final node = createTreeNode([
          (path: "simple.path", value: 1),
          (path: "other.path", value: 2),
        ], (e) => e.path);

        expect(node.children, hasLength(2));
        expect(
          node.children[0],
          isA<InnerTreeNode<({String path, int value})>>(),
        );
        expect(
          node.children[1],
          isA<InnerTreeNode<({String path, int value})>>(),
        );

        final innerNode1 =
            node.children[0] as InnerTreeNode<({String path, int value})>;
        expect(innerNode1.name, equals("simple.path"));

        final innerNode2 =
            node.children[1] as InnerTreeNode<({String path, int value})>;
        expect(innerNode2.name, equals("other.path"));
      });

      test("partial overlap creates shared parent with branches", () {
        final node = createTreeNode([
          (path: "some.simple.path", value: 1),
          (path: "some.other.path", value: 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        expect(
          node.children.first,
          isA<InnerTreeNode<({String path, int value})>>(),
        );

        final innerNode =
            node.children.first as InnerTreeNode<({String path, int value})>;
        expect(innerNode.name, equals("some"));
        expect(innerNode.path, equals("some"));
        expect(innerNode.children, hasLength(2));
        expect(
          innerNode.children[0],
          isA<InnerTreeNode<({String path, int value})>>(),
        );
        expect(
          innerNode.children[1],
          isA<InnerTreeNode<({String path, int value})>>(),
        );

        final branch1 =
            innerNode.children[0] as InnerTreeNode<({String path, int value})>;
        expect(branch1.name, equals("simple.path"));
        expect(branch1.path, equals("some.simple.path"));

        final branch2 =
            innerNode.children[1] as InnerTreeNode<({String path, int value})>;
        expect(branch2.name, equals("other.path"));
        expect(branch2.path, equals("some.other.path"));
      });

      test("deep prefix merging creates common ancestor", () {
        final node = createTreeNode([
          (path: "org.project.module.a", value: 1),
          (path: "org.project.module.b", value: 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final root =
            node.children.first as InnerTreeNode<({String path, int value})>;
        expect(root.name, equals("org.project.module"));
        expect(root.path, equals("org.project.module"));
        expect(root.children, hasLength(2));

        final childA =
            root.children[0] as InnerTreeNode<({String path, int value})>;
        final childB =
            root.children[1] as InnerTreeNode<({String path, int value})>;
        expect(childA.name, equals("a"));
        expect(childA.path, equals("org.project.module.a"));
        expect(childB.name, equals("b"));
        expect(childB.path, equals("org.project.module.b"));
      });
    });

    group("sub-path handling", () {
      test("sub-path added after parent creates nested structure", () {
        final node = createTreeNode([
          (path: "some.simple.path", value: 1),
          (path: "some.simple.path.other", value: 2),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final innerNode =
            node.children.first as InnerTreeNode<({String path, int value})>;

        expect(innerNode.name, equals("some.simple.path"));
        expect(innerNode.path, equals("some.simple.path"));
        expect(innerNode.children, hasLength(2));

        // First child is leaf for the parent path
        expect(
          innerNode.children[0],
          isA<LeafTreeNode<({String path, int value})>>(),
        );
        final parentLeaf =
            innerNode.children[0] as LeafTreeNode<({String path, int value})>;
        expect(parentLeaf.value.value, equals(1));

        // Second child is inner node for the sub-path
        expect(
          innerNode.children[1],
          isA<InnerTreeNode<({String path, int value})>>(),
        );
        final subNode =
            innerNode.children[1] as InnerTreeNode<({String path, int value})>;
        expect(subNode.name, equals("other"));
        expect(subNode.path, equals("some.simple.path.other"));
      });

      test("parent path added after sub-path creates correct structure", () {
        final node = createTreeNode([
          (path: "some.simple.path.other", value: 2),
          (path: "some.simple.path", value: 1),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final innerNode =
            node.children.first as InnerTreeNode<({String path, int value})>;

        expect(innerNode.name, equals("some.simple.path"));
        expect(innerNode.path, equals("some.simple.path"));
        expect(innerNode.children, hasLength(2));

        // Order may differ, but both should be present
        final types = innerNode.children.map((c) => c.runtimeType).toList();
        expect(
          types,
          containsAll([
            InnerTreeNode<({String path, int value})>,
            LeafTreeNode<({String path, int value})>,
          ]),
        );
      });
    });

    group("order invariance", () {
      test("same tree structure regardless of insertion order", () {
        final elements = [
          (path: "a.b.c", value: 1),
          (path: "a.b.d", value: 2),
          (path: "a.e", value: 3),
        ];

        final node1 = createTreeNode(elements, (e) => e.path);
        final node2 = createTreeNode(elements.reversed.toList(), (e) => e.path);

        // Both should have single root "a"
        expect(node1.children, hasLength(1));
        expect(node2.children, hasLength(1));

        final root1 =
            node1.children.first as InnerTreeNode<({String path, int value})>;
        final root2 =
            node2.children.first as InnerTreeNode<({String path, int value})>;

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
          (path: "a", value: 1),
          (path: "a.b", value: 2),
          (path: "a.b.c", value: 3),
          (path: "x.y", value: 4),
        ], (e) => e.path);

        // Should have 2 top-level nodes: "a" and "x.y"
        expect(node.children, hasLength(2));

        final nodeNames = node.children
            .map((c) => (c as InnerTreeNode<({String path, int value})>).name)
            .toSet();
        expect(nodeNames, containsAll(["a", "x.y"]));
      });

      test("deeply nested single path", () {
        final node = createTreeNode([
          (path: "a.b.c.d.e.f", value: 1),
        ], (e) => e.path);

        expect(node.children, hasLength(1));
        final innerNode =
            node.children.first as InnerTreeNode<({String path, int value})>;
        expect(innerNode.name, equals("a.b.c.d.e.f"));
        expect(innerNode.path, equals("a.b.c.d.e.f"));
      });
    });
  });
}
