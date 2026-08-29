plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api("com.typewritermc:service-telemetry-core")
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.api)
    api(libs.kotlin.coroutines.core)
    testImplementation("com.typewritermc:service-telemetry-testing")
}
