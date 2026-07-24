plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-test-fixtures`
}

dependencies {
    implementation("com.typewritermc:service-utils")
    implementation("com.typewritermc:service-telemetry")
    implementation(libs.nats.core)
    implementation(libs.nats.jetstream)
    implementation(libs.kotlin.serialize.json)

    api(libs.skir.client)

    testImplementation(testFixtures("com.typewritermc:service-telemetry"))

    testFixturesImplementation("com.typewritermc:service-utils")
    testFixturesImplementation("com.typewritermc:service-telemetry")
    testFixturesImplementation(libs.nats.core)
    testFixturesImplementation(libs.kotlin.coroutines.core)
}
