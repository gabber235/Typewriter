plugins {
    id("org.gradle.toolchains.foojay-resolver-convention")
}

// Find the libs.versions.toml file by traversing up from the settings directory
var current: java.io.File? = settings.settingsDir
var catalogFile: java.io.File? = null
while (current != null) {
    val searchDir = current!!
    val potential = java.io.File(searchDir, "libs.versions.toml")
    if (potential.exists()) {
        catalogFile = potential
        break
    }
    current = searchDir.parentFile
}

val finalCatalogFile = catalogFile
if (finalCatalogFile != null) {
    dependencyResolutionManagement {
        versionCatalogs {
            create("libs") {
                from(files(finalCatalogFile))
            }
        }
    }
}
