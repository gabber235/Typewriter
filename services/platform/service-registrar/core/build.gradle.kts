plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api("com.typewritermc:service-utils")
    api("com.typewritermc:service-communicator-core")
    api("com.typewritermc:service-telemetry-core")
    api(libs.kotlin.coroutines.core)
    testImplementation(project(":service-registrar-testing"))
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.kotlin.coroutines.test)
}
