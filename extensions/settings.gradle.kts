includeBuild("../engine")
includeBuild("../module-plugin")

val ignoringExtensions: List<String> = emptyList()

val directories = file("./").listFiles()?.filter {
    it.name.endsWith("Extension") && it.isDirectory && it.name !in ignoringExtensions
} ?: emptyList()

for (directory in directories) {
    include(directory.name)
}

pluginManagement {
    includeBuild("../module-plugin")
    repositories {
        mavenLocal()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.gradle.develocity") version ("3.19.2")
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

develocity {
    buildScan {
        termsOfUseUrl = "https://gradle.com/help/legal-terms-of-use"
        termsOfUseAgree = "yes"
        publishing.onlyIf { System.getenv("CI") != null }
    }
}
