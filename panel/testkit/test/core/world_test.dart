import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("two traits for one source fail naming both", () {
    expect(
      () => World.build([signedIn(ada), signedIn(grace)]),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          "message",
          allOf(contains("Ada"), contains("Grace")),
        ),
      ),
    );
  });

  test("a realm without an organization fails with a fix", () {
    expect(
      () => World.build([signedIn(ada), realm()]),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          "message",
          contains("signedIn(user, organization: ...)"),
        ),
      ),
    );
  });

  test("the same seed generates the same values", () {
    List<String> titles(int seed) =>
        Generator(seed).list(5, (generator) => generator.title());

    expect(titles(7), titles(7));
  });
}
