plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":messaging"))
    api(project(":telemetry"))
    api(project(":internal-utils"))
    api(platform(libs.koin.bom))
    api(platform(libs.opentelemetry.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    api(libs.opentelemetry.api)
    implementation(libs.kotlin.serialize.json)
    implementation(libs.mordant)
    testImplementation(libs.koin.test)
    testImplementation(libs.kotlin.coroutines.test)
}
