plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(libs.kotlin.serialize.core)
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.kotlin.serialize.cbor)
}
