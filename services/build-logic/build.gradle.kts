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
