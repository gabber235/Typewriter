plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}
dependencies {
    api(project(":service-registrar-core"))
    implementation("com.typewritermc:service-utils")
    api("com.typewritermc:service-http-core")
    implementation("com.typewritermc:service-communicator-core")
    implementation("com.typewritermc:service-communicator-nats")
    implementation("com.typewritermc:service-communicator-skir")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0")
    testImplementation("com.typewritermc:service-communicator-testing")
    testImplementation("com.typewritermc:service-http-testing")
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.kotlin.coroutines.test)
}
