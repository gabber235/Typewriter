plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    implementation("com.typewritermc:service-utils")
    api("com.typewritermc:service-telemetry-core")
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.api)
    api(libs.kotlin.coroutines.core)
    testImplementation(project(":service-communicator-testing"))
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.kotlin.coroutines.test)
}
