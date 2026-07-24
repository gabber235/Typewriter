plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api(project(":service-communicator-core"))
    api(project(":service-communicator-nats"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    testImplementation(libs.opentelemetry.api)
}
