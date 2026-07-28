plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api(project(":service-registrar-core"))
    api("com.typewritermc:service-http-testing")
    api("com.typewritermc:service-communicator-testing")
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.kotlin.coroutines.test)
}
