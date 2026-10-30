import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("duration text reads every unit, sign and exact microsecond total", () {
    for (final entry in {
      "2w 5d 23h 59m 59s 999ms": 1727999999,
      "-1h 2min 3s": -3723000,
      "+1000us": 1,
      "0ms": 0,
      " 1s ": 1000,
      "-${PortableDurationMilliseconds.maximum}ms":
          -PortableDurationMilliseconds.maximum,
    }.entries) {
      expect(
        entry.key.portableDurationMilliseconds,
        entry.value,
        reason: entry.key,
      );
    }
  });

  test("duration text refuses fractions, partial milliseconds, repeated "
      "units, separators and clock notation", () {
    for (final entry in {
      "1.5s": "Invalid duration format",
      "1us": "Duration must use whole milliseconds",
      "1m 2min": "Duration unit specified multiple times",
      "1h, 2m": "Invalid duration format",
      "01:02:03": "Invalid duration format",
      "${BigInt.from(PortableDurationMilliseconds.maximum) + BigInt.one}ms":
          "Duration exceeds the supported range",
    }.entries) {
      expect(
        () => entry.key.portableDurationMilliseconds,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            "message",
            entry.value,
          ),
        ),
        reason: entry.key,
      );
    }
  });

  test("duration text written for a duration reads back as that duration", () {
    for (final milliseconds in [
      0,
      1,
      -3723000,
      1727999999,
      PortableDurationMilliseconds.maximum,
      -PortableDurationMilliseconds.maximum,
    ]) {
      expect(
        milliseconds.portableDurationText.portableDurationMilliseconds,
        milliseconds,
        reason: milliseconds.portableDurationText,
      );
    }
    expect(3723000.portableDurationText, "1h 2m 3s");
    expect(0.portableDurationText, "0ms");
  });
}
