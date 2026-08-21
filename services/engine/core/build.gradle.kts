plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":engine-types"))
    api("com.typewritermc:loader-core")
    api("com.typewritermc:extension-types")
    api(libs.kotlin.coroutines.core)
    implementation("com.typewritermc:imprint-model")
    implementation(libs.kotlin.reflect)
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.kotlin.coroutines.test)
}
