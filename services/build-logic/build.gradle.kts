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
    implementation(libs.foojay.resolver)
}