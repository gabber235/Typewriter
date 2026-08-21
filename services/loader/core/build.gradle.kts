plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(libs.kotlin.coroutines.core)
    api("com.typewritermc:service-communicator-core")
    api("com.typewritermc:service-registrar-core")
    api("com.typewritermc:service-telemetry-core")
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.kotlin.coroutines.test)
}
