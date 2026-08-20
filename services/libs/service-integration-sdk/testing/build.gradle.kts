plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    testImplementation(project(":service-integration-sdk-client"))
    testImplementation(project(":service-integration-sdk-messaging"))
    testImplementation("com.typewritermc:service-file-transfer-core")
    testImplementation(libs.kotlin.coroutines.test)
}
