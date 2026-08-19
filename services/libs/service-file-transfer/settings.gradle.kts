pluginManagement {
    includeBuild("../../build-logic")
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "service-file-transfer"

include(
    ":service-file-transfer-core",
    ":service-file-transfer-messaging",
    ":service-file-transfer-storage-file",
    ":service-file-transfer-koin",
    ":service-file-transfer-testing",
)
project(":service-file-transfer-core").projectDir = file("core")
project(":service-file-transfer-messaging").projectDir = file("messaging")
project(":service-file-transfer-storage-file").projectDir = file("storage-file")
project(":service-file-transfer-koin").projectDir = file("koin")
project(":service-file-transfer-testing").projectDir = file("testing")
