plugins {
    `kotlin-dsl`
}

group = "com.typewritermc.buildlogic"

repositories {
    mavenCentral()
    google()
    gradlePluginPortal()
}

dependencies {
    implementation(libs.kotlin.gradle.plugin)
    implementation(libs.ktlint.gradle.plugin)
    implementation(libs.detekt.gradle.plugin)
    implementation(libs.foojay.resolver)
    implementation(libs.test.balloon.gradle.plugin)
    implementation(libs.kover.gradle.plugin)
    // run-paper keeps one download service for every project, so its classes must load once, from this
    // classpath. Loaded per project, detekt's older kotlinx-serialization on the settings classpath shadows
    // the one run-task needs, and two projects get two incompatible copies of the shared service.
    implementation(libs.run.task.gradle.plugin)
}

// The game-test convention's build service starts and stops the game pool. It compiles the playtest
// launch module's source folder in with these plugins, as an included build cannot depend on a project
// of the build it configures: one copy of the pool's command and process handling serves the build and
// the unit tests that prove it.
sourceSets.main { java.srcDir("../playtest/launch/src/main/java") }
