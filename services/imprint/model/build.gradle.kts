plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-test-fixtures`
}

dependencies {
    api(libs.kotlin.serialize.core)
    api(libs.kotlin.serialize.cbor)
    api(libs.semver)
}
