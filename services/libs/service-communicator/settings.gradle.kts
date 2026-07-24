pluginManagement {
    includeBuild("../../build-logic")
}
plugins { id("com.typewritermc.settings-conventions") }
rootProject.name = "service-communicator"
include(":service-communicator-core", ":service-communicator-nats", ":service-communicator-skir", ":service-communicator-koin", ":service-communicator-testing")
project(":service-communicator-core").projectDir = file("core")
project(":service-communicator-nats").projectDir = file("nats")
project(":service-communicator-skir").projectDir = file("skir")
project(":service-communicator-koin").projectDir = file("koin")
project(":service-communicator-testing").projectDir = file("testing")
includeBuild("../service-utils")
includeBuild("../service-telemetry")
