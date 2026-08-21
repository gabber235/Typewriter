plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.gradle.buildconfig)
}

version = "1000.0.0"

dependencies {
    implementation(project(":loader-core"))
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation("com.typewritermc:service-registrar-koin")
    implementation("com.typewritermc:service-registrar-storage-file")
    implementation("com.typewritermc:service-registrar-console")
    implementation("com.typewritermc:service-telemetry-koin")
    implementation("com.typewritermc:service-telemetry-console")
    implementation("com.typewritermc:service-utils")
    implementation(libs.clikt)
    implementation(libs.jline)
    implementation(platform(libs.opentelemetry.bom))
    implementation(libs.opentelemetry.sdk)
    implementation(libs.opentelemetry.exporter.otlp)
    implementation(libs.opentelemetry.semconv)
    testImplementation(libs.kotlin.coroutines.test)
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.mockk)
}

buildConfig {
    packageName("com.typewritermc.loader.standalone")
    useKotlinOutput {
        topLevelConstants = true
        internalVisibility = false
    }
    buildConfigField<String>("LOADER_VERSION", provider { "${project.version}" })
}
