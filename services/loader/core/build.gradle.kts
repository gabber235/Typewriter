plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":loader-api"))
    api("com.typewritermc:imprint-model")
    implementation("com.typewritermc:discovery-model")
    api(libs.kotlin.coroutines.core)
    api("com.typewritermc:service-communicator-core")
    implementation("com.typewritermc:service-communicator-skir")
    api("com.typewritermc:service-registrar-core")
    api("com.typewritermc:service-telemetry-core")
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.kotlin.coroutines.test)
}
