plugins {
    id("com.typewritermc.basic-conventions")
}
dependencies {
    api(project(":service-telemetry-core"))
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.sdk)
    api(libs.opentelemetry.sdk.testing)
}
