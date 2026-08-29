plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    alias(libs.plugins.gradle.buildconfig)
    `java-library`
}

buildConfig {
    packageName("com.typewritermc.loader.api")
    useKotlinOutput {
        topLevelConstants = true
        internalVisibility = false
    }
    buildConfigField<String>("HOST_API_VERSION", provider { "${project.version}" })
}

version = "1.0.0"

dependencies {
    api(libs.kotlin.coroutines.core)
    api(libs.kotlin.serialize.core)
    api("com.typewritermc:imprint-model")
    api(project(":messaging"))
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.api)
}
