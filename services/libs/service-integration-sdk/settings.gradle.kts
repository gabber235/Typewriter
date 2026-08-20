pluginManagement {
    includeBuild("../../build-logic")
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "service-integration-sdk"

include(
    ":service-integration-sdk-types",
    ":service-integration-sdk-client",
    ":service-integration-sdk-messaging",
    ":service-integration-sdk-testing",
)

project(":service-integration-sdk-types").projectDir = file("types")
project(":service-integration-sdk-client").projectDir = file("client")
project(":service-integration-sdk-messaging").projectDir = file("messaging")
project(":service-integration-sdk-testing").projectDir = file("testing")

includeBuild("../service-file-transfer")
