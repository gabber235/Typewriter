plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(libs.kotlin.serialize.core)
    implementation(libs.kotlin.serialize.json)
    implementation(libs.mordant)
    implementation("com.typewritermc:service-utils")
    implementation("com.typewritermc:service-communicator")
    implementation("com.typewritermc:service-telemetry")
    implementation(libs.nats.core)
    implementation(libs.opentelemetry.api)
    implementation(libs.opentelemetry.kotlin)

    testImplementation(testFixtures("com.typewritermc:service-telemetry"))
}