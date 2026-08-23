plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api("com.typewritermc:discovery-model")
    api("com.typewritermc:discovery-runtime")
    api("com.typewritermc:typewriter-types-core")
    api(libs.kotlin.coroutines.core)
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.bundles.basic.test)
}
