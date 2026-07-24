plugins {
    id("com.typewritermc.basic-conventions")
}
dependencies {
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.api)
    implementation(libs.opentelemetry.kotlin)
    implementation(libs.opentelemetry.semconv)
    testImplementation(libs.opentelemetry.sdk)
    testImplementation(libs.opentelemetry.sdk.testing)
}
