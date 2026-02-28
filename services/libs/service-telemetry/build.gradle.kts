plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
}

dependencies {
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.api)
    api(libs.opentelemetry.sdk)
    api(libs.opentelemetry.kotlin)
    implementation(libs.opentelemetry.exporter.otlp)
    implementation(libs.opentelemetry.exporter.logging)
    implementation(libs.opentelemetry.semconv)

    testFixturesImplementation(platform(libs.opentelemetry.bom))
    testFixturesImplementation(libs.opentelemetry.api)
    testFixturesImplementation(libs.mockk)
}
