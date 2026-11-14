// The test side of game verification: requirements declared in testBalloon, the checks a body
// writes, and the window rules that judge them from each player's perception stream.
plugins {
    id("com.typewritermc.game-test")
    `java-test-fixtures`
}

dependencies {
    api(project(":playtest-wire"))
    api(libs.test.balloon)
    implementation(libs.kotlin.coroutines.core)
    testImplementation(testFixtures(project(":playtest-wire")))
    testFixturesImplementation(libs.kotlin.coroutines.core)
    // The framework's own test kit: requirements that prove the wipe run two bodies on the same players,
    // and requirements that prove counted work run attempts side by side.
    "gameTestImplementation"(testFixtures(project(":playtest")))
}
