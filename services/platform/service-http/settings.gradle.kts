pluginManagement { includeBuild("../../build-logic") }
plugins { id("com.typewritermc.settings-conventions") }
rootProject.name = "service-http"
include(":service-http-core", ":service-http-jdk", ":service-http-testing")
project(":service-http-core").projectDir = file("core")
project(":service-http-jdk").projectDir = file("jdk")
project(":service-http-testing").projectDir = file("testing")
includeBuild("../service-utils")
includeBuild("../service-telemetry")
