plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":service-integration-sdk-types"))
    api(libs.kotlin.coroutines.core)
}
