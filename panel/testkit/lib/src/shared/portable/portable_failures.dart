import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Matches a call that throws the portable operation failure [failure].
Matcher throwsPortableFailure(skir.FailureId failure) => throwsA(
  isA<skir.PortableOperationFailure>().having(
    (error) => error.failure,
    "failure",
    failure,
  ),
);
