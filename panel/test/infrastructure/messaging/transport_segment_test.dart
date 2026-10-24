import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("identities never split or widen a subject", () {
    expect("writers".transportIdentity, "writers");
    for (final invalid in ["", "a.b", "*", ">", "a b", "{user}"]) {
      expect(invalid.isTransportIdentity, isFalse, reason: invalid);
      expect(() => invalid.transportIdentity, throwsArgumentError);
    }
  });

  test("connection sessions are 32 lowercase hexadecimal characters", () {
    const session = "0123456789abcdef0123456789abcdef";
    expect(session.transportSession, session);
    expect(() => session.toUpperCase().transportSession, throwsArgumentError);
    expect(() => "short".transportSession, throwsArgumentError);
  });
}
