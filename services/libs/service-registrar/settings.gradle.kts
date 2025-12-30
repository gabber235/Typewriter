pluginManagement {
    includeBuild("../../build-logic")
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "service-registrar"

includeBuild("../service-communicator")