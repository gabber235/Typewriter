plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    implementation(project(":internal-utils"))
    api(project(":telemetry"))
    api(project(":protocol"))
    api(platform(libs.koin.bom))
    api(platform(libs.opentelemetry.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    api(libs.okio)
    api(libs.opentelemetry.api)
    api(libs.skir.client)
    implementation(libs.cryptography.provider.jdk)
    implementation(libs.nats.core)
    testImplementation(project(":telemetry"))
    testImplementation(libs.kotlin.coroutines.test)
}
