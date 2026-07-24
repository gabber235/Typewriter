plugins {
    id("com.typewritermc.basic-conventions")
}
dependencies {
    api(project(":service-telemetry-core"))
    testImplementation(platform(libs.opentelemetry.bom))
    testImplementation(libs.opentelemetry.sdk)
    testImplementation(project(":service-telemetry-testing"))
}
