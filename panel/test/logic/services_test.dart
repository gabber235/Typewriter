import "package:fixnum/fixnum.dart";
import "package:flutter_test/flutter_test.dart";
import "package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart";
import "package:typewriter_panel/generated/models/service.pb.dart";
import "package:typewriter_panel/logic/services.dart";

void main() {
  Service createServiceWithState({
    required DateTime lastSeenTime,
    ServiceStatus status = ServiceStatus.SERVICE_STATUS_ONLINE,
  }) {
    final timestamp = Timestamp()
      ..seconds = Int64(lastSeenTime.millisecondsSinceEpoch ~/ 1000);
    final state = ServiceState(status: status, lastSeen: timestamp);
    return Service(serviceId: "test-id", state: state);
  }

  Service createServiceWithoutState() {
    return Service(serviceId: "test-id");
  }

  group("ServiceExtension.isOnline", () {
    test(
      "returns true when status is ONLINE and lastSeen is within 2 minutes",
      () {
        final now = DateTime.now();
        final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
        final service = createServiceWithState(lastSeenTime: oneMinuteAgo);

        expect(service.isOnline, isTrue);
      },
    );

    test("returns true when lastSeen is just under 2 minutes ago", () {
      final now = DateTime.now();
      final justUnder2Minutes = now.subtract(
        const Duration(minutes: 1, seconds: 59),
      );
      final service = createServiceWithState(lastSeenTime: justUnder2Minutes);

      expect(service.isOnline, isTrue);
    });

    test("returns false when lastSeen is exactly 2 minutes ago", () {
      final now = DateTime.now();
      final exactly2MinutesAgo = now.subtract(const Duration(minutes: 2));
      final service = createServiceWithState(lastSeenTime: exactly2MinutesAgo);

      expect(service.isOnline, isFalse);
    });

    test("returns false when lastSeen is older than 2 minutes", () {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final service = createServiceWithState(lastSeenTime: fiveMinutesAgo);

      expect(service.isOnline, isFalse);
    });

    test("returns false when lastSeen is much older", () {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final service = createServiceWithState(lastSeenTime: oneDayAgo);

      expect(service.isOnline, isFalse);
    });

    test("returns false when state is not set", () {
      final service = createServiceWithoutState();

      expect(service.isOnline, isFalse);
    });

    test("returns false when status is OFFLINE even with recent lastSeen", () {
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
      final service = createServiceWithState(
        lastSeenTime: oneMinuteAgo,
        status: ServiceStatus.SERVICE_STATUS_OFFLINE,
      );

      expect(service.isOnline, isFalse);
    });

    test("returns false when status is UNSPECIFIED with recent lastSeen", () {
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
      final service = createServiceWithState(
        lastSeenTime: oneMinuteAgo,
        status: ServiceStatus.SERVICE_STATUS_UNSPECIFIED,
      );

      expect(service.isOnline, isTrue);
    });
  });

  group("ServiceExtension.lastSeenLabel", () {
    test('returns "Just now" for less than 60 seconds', () {
      final now = DateTime.now();
      final thirtySecondsAgo = now.subtract(const Duration(seconds: 30));
      final service = createServiceWithState(lastSeenTime: thirtySecondsAgo);

      expect(service.lastSeenLabel, equals("Just now"));
    });

    test('returns "Just now" at exactly 59 seconds', () {
      final now = DateTime.now();
      final fiftyNineSecondsAgo = now.subtract(const Duration(seconds: 59));
      final service = createServiceWithState(lastSeenTime: fiftyNineSecondsAgo);

      expect(service.lastSeenLabel, equals("Just now"));
    });

    test("returns minutes format at exactly 60 seconds", () {
      final now = DateTime.now();
      final sixtySecondsAgo = now.subtract(const Duration(seconds: 60));
      final service = createServiceWithState(lastSeenTime: sixtySecondsAgo);

      expect(service.lastSeenLabel, equals("1m ago"));
    });

    test("returns minutes format for 1-59 minutes", () {
      final now = DateTime.now();

      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final service5m = createServiceWithState(lastSeenTime: fiveMinutesAgo);
      expect(service5m.lastSeenLabel, equals("5m ago"));

      final fiftyNineMinutesAgo = now.subtract(const Duration(minutes: 59));
      final service59m = createServiceWithState(
        lastSeenTime: fiftyNineMinutesAgo,
      );
      expect(service59m.lastSeenLabel, equals("59m ago"));
    });

    test("returns hours format for 1-23 hours", () {
      final now = DateTime.now();

      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      final service2h = createServiceWithState(lastSeenTime: twoHoursAgo);
      expect(service2h.lastSeenLabel, equals("2h ago"));

      final twentyThreeHoursAgo = now.subtract(const Duration(hours: 23));
      final service23h = createServiceWithState(
        lastSeenTime: twentyThreeHoursAgo,
      );
      expect(service23h.lastSeenLabel, equals("23h ago"));
    });

    test("returns days format for 24+ hours", () {
      final now = DateTime.now();

      final oneDayAgo = now.subtract(const Duration(days: 1));
      final service1d = createServiceWithState(lastSeenTime: oneDayAgo);
      expect(service1d.lastSeenLabel, equals("1d ago"));

      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final service2d = createServiceWithState(lastSeenTime: twoDaysAgo);
      expect(service2d.lastSeenLabel, equals("2d ago"));

      final tenDaysAgo = now.subtract(const Duration(days: 10));
      final service10d = createServiceWithState(lastSeenTime: tenDaysAgo);
      expect(service10d.lastSeenLabel, equals("10d ago"));
    });

    test('returns "Never" when state is not set', () {
      final service = createServiceWithoutState();

      expect(service.lastSeenLabel, equals("Never"));
    });
  });

  group("ServiceExtension.displayName", () {
    test("returns name when set", () {
      final service = Service(serviceId: "test-id", name: "My Server");

      expect(service.displayName, equals("My Server"));
    });

    test('returns "Unnamed Service" when name is empty', () {
      final service = Service(serviceId: "test-id", name: "");

      expect(service.displayName, equals("Unnamed Service"));
    });

    test('returns "Unnamed Service" when name is not set', () {
      final service = Service(serviceId: "test-id");

      expect(service.displayName, equals("Unnamed Service"));
    });
  });

  group("ServiceExtension.typeLabel", () {
    test('returns "Engine" for engine type', () {
      final service = Service(
        serviceId: "test-id",
        serviceTypes: [ServiceType.SERVICE_TYPE_ENGINE],
      );

      expect(service.typeLabel, equals("Engine"));
    });

    test('returns "Realm" for realm type', () {
      final service = Service(
        serviceId: "test-id",
        serviceTypes: [ServiceType.SERVICE_TYPE_REALM],
      );

      expect(service.typeLabel, equals("Realm"));
    });

    test('returns "Engine & Realm" for both types', () {
      final service = Service(
        serviceId: "test-id",
        serviceTypes: [
          ServiceType.SERVICE_TYPE_ENGINE,
          ServiceType.SERVICE_TYPE_REALM,
        ],
      );

      expect(service.typeLabel, equals("Engine & Realm"));
    });

    test('returns "Unknown" for no types', () {
      final service = Service(serviceId: "test-id");

      expect(service.typeLabel, equals("Unknown"));
    });
  });
}
