import "package:fixnum/fixnum.dart";
import "package:flutter_test/flutter_test.dart";
import "package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart";
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/services.dart";

void main() {
  Service createServiceWithLastSeen(DateTime lastSeenTime) {
    final timestamp = Timestamp()
      ..seconds = Int64(lastSeenTime.millisecondsSinceEpoch ~/ 1000);
    return Service(id: "test-id", lastSeen: timestamp);
  }

  Service createServiceWithoutLastSeen() {
    return Service(id: "test-id");
  }

  group("ServiceExtension.isOnline", () {
    test("returns true when lastSeen is within 2 minutes", () {
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
      final service = createServiceWithLastSeen(oneMinuteAgo);

      expect(service.isOnline, isTrue);
    });

    test("returns true when lastSeen is just under 2 minutes ago", () {
      final now = DateTime.now();
      final justUnder2Minutes = now.subtract(
        const Duration(minutes: 1, seconds: 59),
      );
      final service = createServiceWithLastSeen(justUnder2Minutes);

      expect(service.isOnline, isTrue);
    });

    test("returns false when lastSeen is exactly 2 minutes ago", () {
      final now = DateTime.now();
      final exactly2MinutesAgo = now.subtract(const Duration(minutes: 2));
      final service = createServiceWithLastSeen(exactly2MinutesAgo);

      expect(service.isOnline, isFalse);
    });

    test("returns false when lastSeen is older than 2 minutes", () {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final service = createServiceWithLastSeen(fiveMinutesAgo);

      expect(service.isOnline, isFalse);
    });

    test("returns false when lastSeen is much older", () {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final service = createServiceWithLastSeen(oneDayAgo);

      expect(service.isOnline, isFalse);
    });

    test("returns false when lastSeen is not set", () {
      final service = createServiceWithoutLastSeen();

      expect(service.isOnline, isFalse);
    });
  });

  group("ServiceExtension.lastSeenLabel", () {
    test('returns "Just now" for less than 60 seconds', () {
      final now = DateTime.now();
      final thirtySecondsAgo = now.subtract(const Duration(seconds: 30));
      final service = createServiceWithLastSeen(thirtySecondsAgo);

      expect(service.lastSeenLabel, equals("Just now"));
    });

    test('returns "Just now" at exactly 59 seconds', () {
      final now = DateTime.now();
      final fiftyNineSecondsAgo = now.subtract(const Duration(seconds: 59));
      final service = createServiceWithLastSeen(fiftyNineSecondsAgo);

      expect(service.lastSeenLabel, equals("Just now"));
    });

    test('returns minutes format at exactly 60 seconds', () {
      final now = DateTime.now();
      final sixtySecondsAgo = now.subtract(const Duration(seconds: 60));
      final service = createServiceWithLastSeen(sixtySecondsAgo);

      expect(service.lastSeenLabel, equals("1m ago"));
    });

    test("returns minutes format for 1-59 minutes", () {
      final now = DateTime.now();

      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final service5m = createServiceWithLastSeen(fiveMinutesAgo);
      expect(service5m.lastSeenLabel, equals("5m ago"));

      final fiftyNineMinutesAgo = now.subtract(const Duration(minutes: 59));
      final service59m = createServiceWithLastSeen(fiftyNineMinutesAgo);
      expect(service59m.lastSeenLabel, equals("59m ago"));
    });

    test("returns hours format for 1-23 hours", () {
      final now = DateTime.now();

      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      final service2h = createServiceWithLastSeen(twoHoursAgo);
      expect(service2h.lastSeenLabel, equals("2h ago"));

      final twentyThreeHoursAgo = now.subtract(const Duration(hours: 23));
      final service23h = createServiceWithLastSeen(twentyThreeHoursAgo);
      expect(service23h.lastSeenLabel, equals("23h ago"));
    });

    test("returns days format for 24+ hours", () {
      final now = DateTime.now();

      final oneDayAgo = now.subtract(const Duration(days: 1));
      final service1d = createServiceWithLastSeen(oneDayAgo);
      expect(service1d.lastSeenLabel, equals("1d ago"));

      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final service2d = createServiceWithLastSeen(twoDaysAgo);
      expect(service2d.lastSeenLabel, equals("2d ago"));

      final tenDaysAgo = now.subtract(const Duration(days: 10));
      final service10d = createServiceWithLastSeen(tenDaysAgo);
      expect(service10d.lastSeenLabel, equals("10d ago"));
    });

    test('returns "Never" when lastSeen is not set', () {
      final service = createServiceWithoutLastSeen();

      expect(service.lastSeenLabel, equals("Never"));
    });
  });

  group("ServiceExtension.displayName", () {
    test("returns name when set", () {
      final service = Service(id: "test-id", name: "My Server");

      expect(service.displayName, equals("My Server"));
    });

    test('returns "Unnamed Service" when name is empty', () {
      final service = Service(id: "test-id", name: "");

      expect(service.displayName, equals("Unnamed Service"));
    });

    test('returns "Unnamed Service" when name is not set', () {
      final service = Service(id: "test-id");

      expect(service.displayName, equals("Unnamed Service"));
    });
  });

  group("ServiceExtension.typeLabel", () {
    test('returns "Engine" for engine type', () {
      final service = Service(
        id: "test-id",
        serviceTypes: [ServiceType.SERVICE_TYPE_ENGINE],
      );

      expect(service.typeLabel, equals("Engine"));
    });

    test('returns "Realm" for realm type', () {
      final service = Service(
        id: "test-id",
        serviceTypes: [ServiceType.SERVICE_TYPE_REALM],
      );

      expect(service.typeLabel, equals("Realm"));
    });

    test('returns "Engine & Realm" for both types', () {
      final service = Service(
        id: "test-id",
        serviceTypes: [
          ServiceType.SERVICE_TYPE_ENGINE,
          ServiceType.SERVICE_TYPE_REALM,
        ],
      );

      expect(service.typeLabel, equals("Engine & Realm"));
    });

    test('returns "Unknown" for no types', () {
      final service = Service(id: "test-id");

      expect(service.typeLabel, equals("Unknown"));
    });
  });
}
