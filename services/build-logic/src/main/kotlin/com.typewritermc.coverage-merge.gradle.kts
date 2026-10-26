// Merges the Kover coverage of every project in this Gradle build into the root's `koverXmlReport`.
// Apply it to the root of a build whose projects use the basic conventions.
//
// Tests and the report must run in one Gradle invocation. A report built in a later invocation from tests that
// were up to date can miss coverage (Kotlin/kotlinx-kover#803).
plugins {
    id("org.jetbrains.kotlinx.kover")
}

// Kover resolves its reporter from Maven Central.
repositories {
    mavenCentral()
}

dependencies {
    subprojects.forEach { "kover"(it) }
}
