// The test side of game verification: requirements declared in testBalloon, the checks a body
// writes, and the window rules that judge them from each player's perception stream.
plugins {
    id("com.typewritermc.game-test")
}

dependencies {
    api(project(":playtest-wire"))
    api(libs.test.balloon)
    implementation(libs.kotlin.coroutines.core)
}
