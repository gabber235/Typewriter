import "package:flutter_test/flutter_test.dart";
import "package:pub_semver/pub_semver.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/version_filter.dart";

Version v(int epoch, int major, int minor, int patch) =>
    Version(epoch * 1000 + major, minor, patch);

void main() {
  group("VersionFilterParser.parse", () {
    test("parses fixed version without epoch", () {
      final f = VersionFilterParser.parse(query: "1.2.3", hasEpoch: false);

      expect(f.epoch, isA<AnyPart>());
      expect(f.semanticMajor, isA<FixedPart>());
      expect((f.semanticMajor as FixedPart).value, 1);
      expect((f.minor as FixedPart).value, 2);
      expect((f.patch as FixedPart).value, 3);

      expect(f.display(false), "1.2.3");
      expect(f.display(true), "*.1.2.3");

      expect(f.matches(v(0, 1, 2, 3)), isTrue);
      expect(f.matches(v(0, 1, 2, 4)), isFalse);
      expect(f.matches(v(1, 1, 2, 3)), isTrue); // epoch ignored by matcher
    });

    test("parses per-segment ranges without epoch", () {
      final f = VersionFilterParser.parse(query: "1.3-4.0-1", hasEpoch: false);

      expect(f.epoch, isA<AnyPart>());
      expect((f.semanticMajor as FixedPart).value, 1);
      expect((f.minor as RangePart).from, 3);
      expect((f.minor as RangePart).to, 4);
      expect((f.patch as RangePart).from, 0);
      expect((f.patch as RangePart).to, 1);

      expect(f.display(false), "1.3-4.0-1");
      expect(f.display(true), "*.1.3-4.0-1");
    });

    test("parses with epoch", () {
      final f = VersionFilterParser.parse(query: "2.1.0-2.0", hasEpoch: true);

      expect((f.epoch as FixedPart).value, 2);
      expect((f.semanticMajor as FixedPart).value, 1);
      expect((f.minor as RangePart).from, 0);
      expect((f.minor as RangePart).to, 2);
      expect((f.patch as FixedPart).value, 0);

      expect(f.display(true), "2.1.0-2.0");
    });

    test("parses wildcard parts", () {
      final f = VersionFilterParser.parse(query: "*.1.*.*", hasEpoch: true);

      expect(f.epoch, isA<AnyPart>());
      expect((f.semanticMajor as FixedPart).value, 1);
      expect(f.minor, isA<AnyPart>());
      expect(f.patch, isA<AnyPart>());

      expect(f.display(true), "*.1.*.*");
    });
  });

  group("VersionFilter.expand", () {
    test("expands fixed version without epoch by fixing epoch=0", () {
      final f = VersionFilterParser.parse(
        query: "1.2.3",
        hasEpoch: false,
      ).copyWith(epoch: const FixedPart(0));

      final list = f.expand();

      expect(list.length, 1);
      expect(list.first, v(0, 1, 2, 3));
    });

    test("expands minor/patch ranges without epoch by fixing epoch=0", () {
      final f = VersionFilterParser.parse(
        query: "1.3-4.0-1",
        hasEpoch: false,
      ).copyWith(epoch: const FixedPart(0));

      final list = f.expand();

      // minors: 3..4 (2) × patches: 0..1 (2) = 4
      expect(list.length, 4);
      expect(
        list,
        containsAllInOrder([
          v(0, 1, 3, 0),
          v(0, 1, 3, 1),
          v(0, 1, 4, 0),
          v(0, 1, 4, 1),
        ]),
      );
    });

    test("expands ranges across epoch and major with epoch=true", () {
      final f = VersionFilterParser.parse(query: "1-2.0-1.0.0", hasEpoch: true);

      final list = f.expand();

      // epochs: 1..2 (2) × majors: 0..1 (2) × minor: 0 × patch: 0 = 4
      expect(list.length, 4);
      expect(
        list,
        unorderedEquals([
          v(1, 0, 0, 0),
          v(1, 1, 0, 0),
          v(2, 0, 0, 0),
          v(2, 1, 0, 0),
        ]),
      );
    });

    test("throws when any segment is AnyPart (epoch Any)", () {
      final f = VersionFilterParser.parse(query: "1.2.3", hasEpoch: false);
      expect(f.expand, throwsA(isA<FormatException>()));
    });

    test("throws when any segment is AnyPart (patch Any)", () {
      final f = VersionFilterParser.parse(
        query: "1.2.*",
        hasEpoch: false,
      ).copyWith(epoch: const FixedPart(0));
      expect(f.expand, throwsA(isA<FormatException>()));
    });
  });
}
