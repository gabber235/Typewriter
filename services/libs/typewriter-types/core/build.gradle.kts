plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(libs.kotlin.serialize.core)
    testImplementation(libs.kotlin.serialize.cbor)
}
