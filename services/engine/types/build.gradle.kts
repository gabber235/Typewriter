plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api("com.typewritermc:library-types")
    api("com.typewritermc:typewriter-types-core")
    implementation(libs.semver)
}
