plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":typewriter-api"))
    implementation(libs.kotlin.serialize.json)
    implementation(libs.semver)
}
