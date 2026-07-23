plugins {
    id("org.gradle.toolchains.foojay-resolver-convention")
}

// Find the libs.versions.toml file by traversing up from the settings directory
var current: File? = settings.settingsDir
var catalogFile: File? = null
while (current != null) {
    val searchDir = current!!
    val potential = File(searchDir, "libs.versions.toml")
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
