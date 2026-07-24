plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation(libs.kotlin.coroutines.core)
    implementation(libs.kotlin.logging.jvm)
    implementation(libs.kotlin.serialize.core)
    implementation(libs.kotlin.serialize.json)
    implementation(libs.mordant)
    implementation("com.typewritermc:service-utils")
    implementation("com.typewritermc:service-communicator-core")
    implementation("com.typewritermc:service-communicator-nats")
    implementation("com.typewritermc:service-communicator-skir")
    implementation("com.typewritermc:service-communicator-koin")
    implementation("com.typewritermc:service-telemetry-core")
    implementation("com.typewritermc:service-telemetry-koin")
    implementation(libs.nats.core)
    implementation(libs.opentelemetry.api)
    implementation(libs.opentelemetry.kotlin)

    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.mockk)
    testImplementation(libs.kotlin.coroutines.test)
}