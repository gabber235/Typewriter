plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":service-integration-sdk-types"))
    api("com.typewritermc:service-file-transfer-core")
    api(libs.kotlin.coroutines.core)
}
