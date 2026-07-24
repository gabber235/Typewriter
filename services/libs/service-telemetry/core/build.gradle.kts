plugins {
    id("com.typewritermc.basic-conventions")
}
dependencies {
    implementation("com.typewritermc:service-utils")
    api(libs.kotlin.coroutines.core)
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.api)
    implementation(libs.opentelemetry.kotlin)
    implementation(libs.opentelemetry.semconv)
    testImplementation(libs.kotlin.coroutines.test)
    testImplementation(libs.opentelemetry.sdk)
    testImplementation(libs.opentelemetry.sdk.testing)
}
