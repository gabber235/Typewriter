plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api("com.typewritermc:imprint-model")
    api("com.typewritermc:typewriter-types-core")
    api(libs.kotlin.serialize.core)
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.bundles.basic.test)
}
