plugins { id("com.typewritermc.basic-conventions") }

dependencies {
    api(project(":service-registrar-core"))
    api(project(":service-registrar-runtime"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    implementation("com.typewritermc:service-http-core")
    api("com.typewritermc:service-http-jdk")
    implementation("com.typewritermc:service-telemetry-core")
    implementation(libs.opentelemetry.api)
    testImplementation(project(":service-registrar-testing"))
    testImplementation("com.typewritermc:service-http-testing")
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.koin.test)
    testImplementation(libs.kotlin.coroutines.test)
}
