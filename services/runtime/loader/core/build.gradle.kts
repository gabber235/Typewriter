plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    alias(libs.plugins.gradle.buildconfig)
    `java-library`
}

buildConfig {
    packageName("com.typewritermc.loader")
    useKotlinOutput {
        topLevelConstants = true
        internalVisibility = false
    }
    buildConfigField<String>("LOADER_VERSION", provider { "${project.version}" })
}

dependencies {
    api(project(":loader-api"))
    api("com.typewritermc:imprint-model")
    implementation(project(":typewriter-api"))
    api(libs.kotlin.coroutines.core)
    api(project(":service-sdk"))
    api(project(":telemetry"))
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation(project(":telemetry"))
    implementation(project(":telemetry"))
    implementation(project(":internal-utils"))
    implementation(platform(libs.opentelemetry.bom))
    implementation(libs.opentelemetry.sdk)
    implementation(libs.opentelemetry.exporter.otlp)
    implementation(libs.opentelemetry.semconv)
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.kotlin.coroutines.test)
}
