plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    testImplementation(project(":service-file-transfer-core"))
    testImplementation(project(":service-file-transfer-messaging"))
    testImplementation(project(":service-file-transfer-storage-file"))
    testImplementation(libs.kotlin.coroutines.test)
}
