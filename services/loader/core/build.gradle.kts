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
    implementation("com.typewritermc:discovery-model")
    api(libs.kotlin.coroutines.core)
    api("com.typewritermc:service-communicator-core")
    implementation("com.typewritermc:service-communicator-skir")
    api("com.typewritermc:service-registrar-core")
    api("com.typewritermc:service-telemetry-core")
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation("com.typewritermc:service-registrar-koin")
    implementation("com.typewritermc:service-registrar-storage-file")
    implementation("com.typewritermc:service-registrar-console")
    implementation("com.typewritermc:service-telemetry-koin")
    implementation("com.typewritermc:service-telemetry-console")
    implementation("com.typewritermc:service-utils")
    implementation(platform(libs.opentelemetry.bom))
    implementation(libs.opentelemetry.sdk)
    implementation(libs.opentelemetry.exporter.otlp)
    implementation(libs.opentelemetry.semconv)
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.kotlin.coroutines.test)
}
