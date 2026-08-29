plugins {
    id("com.typewritermc.basic-conventions")
}
dependencies {
    api(project(":service-telemetry-core"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    testImplementation(platform(libs.opentelemetry.bom))
    testImplementation(libs.opentelemetry.sdk)
    testImplementation(project(":service-telemetry-testing"))
}
