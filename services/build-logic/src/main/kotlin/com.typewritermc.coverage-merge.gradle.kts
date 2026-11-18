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

// Only projects that measure coverage join. A project without Kover (the Fabric client, a plain Java
// agent) has no Kover variant, and depending on it makes the root resolve that project's own
// dependencies from the root's repositories.
subprojects.forEach { serviceProject ->
    serviceProject.pluginManager.withPlugin("org.jetbrains.kotlinx.kover") {
        dependencies { "kover"(project(serviceProject.path)) }
    }
}
