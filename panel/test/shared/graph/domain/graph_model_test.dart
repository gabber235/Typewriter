import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("GraphElement", () {
    group("inside", () {
      test("element fully inside another returns true", () {
        final outer = GraphElement(
          id: GraphIdentifier("outer"),
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          builder: (_) => const SizedBox(),
        );
        final inner = GraphElement(
          id: GraphIdentifier("inner"),
          x: 2,
          y: 2,
          width: 3,
          height: 3,
          builder: (_) => const SizedBox(),
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
          builder: (_) => const SizedBox(),
        );
        final partial = GraphElement(
          id: GraphIdentifier("partial"),
          x: 8,
          y: 8,
          width: 5,
          height: 5,
          builder: (_) => const SizedBox(),
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
          builder: (_) => const SizedBox(),
        );
        final exact = GraphElement(
          id: GraphIdentifier("exact"),
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          builder: (_) => const SizedBox(),
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
          builder: (_) => const SizedBox(),
        );
        final outside = GraphElement(
          id: GraphIdentifier("outside"),
          x: 20,
          y: 20,
          width: 5,
          height: 5,
          builder: (_) => const SizedBox(),
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
          builder: (_) => const SizedBox(),
        );
        final high = GraphElement(
          id: GraphIdentifier("high"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          priority: 10,
          builder: (_) => const SizedBox(),
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
          builder: (_) => const SizedBox(),
        );
        final b = GraphElement(
          id: GraphIdentifier("b"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          priority: 5,
          builder: (_) => const SizedBox(),
        );

        expect(a.compareTo(b), equals(0));
      });
    });

    test("elements are equal exactly when their ids are", () {
      final small = graphElement("same", width: 1, height: 1);
      final large = graphElement("same", x: 10, y: 10, width: 11, height: 11);

      expect(small, equals(large));
      expect(small.hashCode, large.hashCode);
      expect(graphElement("a"), isNot(equals(graphElement("b"))));
    });
  });

  group("GraphEdge", () {
    group("connectsTo", () {
      test("returns true when element is source", () {
        final element = GraphElement(
          id: GraphIdentifier("element-1"),
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          builder: (_) => const SizedBox(),
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
          builder: (_) => const SizedBox(),
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
          builder: (_) => const SizedBox(),
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
  });
}
