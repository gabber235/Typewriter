// A second module's game requirements, run by a test JVM of their own: they share the one game pool
// with the framework's requirements, as every module's and extension's requirements will.
plugins {
    id("com.typewritermc.game-test")
}

dependencies {
    "gameTestImplementation"(project(":playtest"))
}
