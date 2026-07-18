import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/edge_side.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_edge.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_element.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_identifier.dart";

void main() {
  group("EdgeSide", () {
    group("axis", () {
      test("left returns horizontal", () {
        expect(EdgeSide.left.axis, equals(Axis.horizontal));
      });

      test("right returns horizontal", () {
        expect(EdgeSide.right.axis, equals(Axis.horizontal));
      });

      test("top returns vertical", () {
        expect(EdgeSide.top.axis, equals(Axis.vertical));
      });

      test("bottom returns vertical", () {
        expect(EdgeSide.bottom.axis, equals(Axis.vertical));
      });
    });

    group("unitVector", () {
      test("left returns (-1, 0)", () {
        expect(EdgeSide.left.unitVector, equals(const Offset(-1, 0)));
      });

      test("right returns (1, 0)", () {
        expect(EdgeSide.right.unitVector, equals(const Offset(1, 0)));
      });

      test("top returns (0, -1)", () {
        expect(EdgeSide.top.unitVector, equals(const Offset(0, -1)));
      });

      test("bottom returns (0, 1)", () {
        expect(EdgeSide.bottom.unitVector, equals(const Offset(0, 1)));
      });
    });
  });

  group("GraphElement", () {
    Widget dummyBuilder(BuildContext context) => const SizedBox();

    group("inside", () {
      test("element fully inside another returns true", () {
        final outer = GraphElement(
          id: GraphIdentifier("outer"),
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          builder: dummyBuilder,
        );
        final inner = GraphElement(
          id: GraphIdentifier("inner"),
          x: 2,
          y: 2,
          width: 3,
          height: 3,
          builder: dummyBuilder,
        );

        expect(inner.inside(outer), isTrue);
      });

      test("element partially outside returns false", () {
        final outer = GraphElement(
          id: GraphIdentifier("outer"),
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          builder: dummyBuilder,
        );
        final partial = GraphElement(
          id: GraphIdentifier("partial"),
          x: 8,
          y: 8,
          width: 5,
          height: 5,
          builder: dummyBuilder,
        );

        expect(partial.inside(outer), isFalse);
      });

      test("element exactly matching boundary returns true", () {
        final outer = GraphElement(
          id: GraphIdentifier("outer"),
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          builder: dummyBuilder,
        );
        final exact = GraphElement(
          id: GraphIdentifier("exact"),
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          builder: dummyBuilder,
        );

        expect(exact.inside(outer), isTrue);
      });

      test("element outside returns false", () {
        final outer = GraphElement(
          id: GraphIdentifier("outer"),
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          builder: dummyBuilder,
        );
        final outside = GraphElement(
          id: GraphIdentifier("outside"),
          x: 20,
          y: 20,
          width: 5,
          height: 5,
          builder: dummyBuilder,
        );

        expect(outside.inside(outer), isFalse);
      });
    });

    group("compareTo", () {
      test("lower priority comes before higher priority", () {
        final low = GraphElement(
          id: GraphIdentifier("low"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          priority: 1,
          builder: dummyBuilder,
        );
        final high = GraphElement(
          id: GraphIdentifier("high"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          priority: 10,
          builder: dummyBuilder,
        );

        expect(low.compareTo(high), lessThan(0));
        expect(high.compareTo(low), greaterThan(0));
      });

      test("same priority returns zero", () {
        final a = GraphElement(
          id: GraphIdentifier("a"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          priority: 5,
          builder: dummyBuilder,
        );
        final b = GraphElement(
          id: GraphIdentifier("b"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          priority: 5,
          builder: dummyBuilder,
        );

        expect(a.compareTo(b), equals(0));
      });
    });

    group("equality", () {
      test("elements with same id are equal", () {
        final a = GraphElement(
          id: GraphIdentifier("same-id"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          builder: dummyBuilder,
        );
        final b = GraphElement(
          id: GraphIdentifier("same-id"),
          x: 10,
          y: 10,
          width: 5,
          height: 5,
          builder: dummyBuilder,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test("elements with different id are not equal", () {
        final a = GraphElement(
          id: GraphIdentifier("id-a"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          builder: dummyBuilder,
        );
        final b = GraphElement(
          id: GraphIdentifier("id-b"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          builder: dummyBuilder,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group("copyWith", () {
      test("copies with new values", () {
        final original = GraphElement(
          id: GraphIdentifier("original"),
          x: 1,
          y: 2,
          width: 3,
          height: 4,
          priority: 5,
          builder: dummyBuilder,
        );

        final copied = original.copyWith(x: 10, y: 20);

        expect(copied.x, equals(10));
        expect(copied.y, equals(20));
        expect(copied.width, equals(3));
        expect(copied.height, equals(4));
        expect(copied.priority, equals(5));
      });
    });
  });

  group("GraphEdge", () {
    Widget dummyBuilder(BuildContext context) => const SizedBox();

    group("connectsTo", () {
      test("returns true when element is source", () {
        final element = GraphElement(
          id: GraphIdentifier("element-1"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          builder: dummyBuilder,
        );
        final edge = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("element-1"),
          target: GraphIdentifier("element-2"),
          color: Colors.red,
        );

        expect(edge.connectsTo(element), isTrue);
      });

      test("returns true when element is target", () {
        final element = GraphElement(
          id: GraphIdentifier("element-2"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          builder: dummyBuilder,
        );
        final edge = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("element-1"),
          target: GraphIdentifier("element-2"),
          color: Colors.red,
        );

        expect(edge.connectsTo(element), isTrue);
      });

      test("returns false when element is neither source nor target", () {
        final element = GraphElement(
          id: GraphIdentifier("element-3"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          builder: dummyBuilder,
        );
        final edge = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("element-1"),
          target: GraphIdentifier("element-2"),
          color: Colors.red,
        );

        expect(edge.connectsTo(element), isFalse);
      });
    });

    group("equality", () {
      test("edges with same properties are equal", () {
        final a = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("src"),
          target: GraphIdentifier("tgt"),
          color: Colors.red,
          sourceSide: EdgeSide.right,
          targetSide: EdgeSide.left,
        );
        final b = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("src"),
          target: GraphIdentifier("tgt"),
          color: Colors.red,
          sourceSide: EdgeSide.right,
          targetSide: EdgeSide.left,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test("edges with different colors are not equal", () {
        final a = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("src"),
          target: GraphIdentifier("tgt"),
          color: Colors.red,
        );
        final b = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("src"),
          target: GraphIdentifier("tgt"),
          color: Colors.blue,
        );

        expect(a, isNot(equals(b)));
      });

      test("edges with different sides are not equal", () {
        final a = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("src"),
          target: GraphIdentifier("tgt"),
          color: Colors.red,
          sourceSide: EdgeSide.right,
        );
        final b = GraphEdge(
          id: "edge-1",
          source: GraphIdentifier("src"),
          target: GraphIdentifier("tgt"),
          color: Colors.red,
          sourceSide: EdgeSide.bottom,
        );

        expect(a, isNot(equals(b)));
      });
    });
  });
}
