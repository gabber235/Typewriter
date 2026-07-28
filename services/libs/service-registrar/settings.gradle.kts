pluginManagement { includeBuild("../../build-logic") }
plugins { id("com.typewritermc.settings-conventions") }
rootProject.name = "service-registrar"
include(":service-registrar-core", ":service-registrar-runtime", ":service-registrar-storage-file", ":service-registrar-console", ":service-registrar-koin", ":service-registrar-testing")
project(":service-registrar-core").projectDir = file("core")
project(":service-registrar-runtime").projectDir = file("runtime")
project(":service-registrar-storage-file").projectDir = file("storage-file")
project(":service-registrar-console").projectDir = file("console")
project(":service-registrar-koin").projectDir = file("koin")
project(":service-registrar-testing").projectDir = file("testing")
includeBuild("../service-utils")
includeBuild("../service-communicator")
includeBuild("../service-telemetry")
includeBuild("../service-http")
