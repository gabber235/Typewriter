import java.util.jar.Attributes
import java.util.jar.JarFile

plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    alias(libs.plugins.gradle.buildconfig)
}

dependencies {
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation(libs.kotlin.coroutines.core)
    implementation(libs.logback)
    implementation("com.typewritermc:service-utils")
    implementation("com.typewritermc:service-telemetry-console")
    implementation("com.typewritermc:service-communicator-skir")
    implementation("com.typewritermc:service-file-transfer-core")
    implementation("com.typewritermc:service-file-transfer-storage-file")
    imprintHostApi("com.typewritermc:loader-api")
    implementation("com.typewritermc:engine-types")
    implementation("com.typewritermc:discovery-model")
    implementation("com.typewritermc:element-types")
    implementation("com.typewritermc:library-types")
    implementation("com.typewritermc:presentation-types")
    implementation("com.typewritermc:page-types")
    implementation("com.typewritermc:realm-capability-types")
    implementation("com.typewritermc:typewriter-types-skir")
    implementation(libs.surrealdb.java.sdk)

    testImplementation("com.typewritermc:service-communicator-testing")
    testImplementation("com.typewritermc:service-file-transfer-messaging")
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation("com.typewritermc:loader-api")
    testImplementation(libs.mockk)
    testImplementation(libs.kotlin.coroutines.test)
}

typewriter {
    realm {
        id = "typewritermc:realm"
        version = "1.0.0"
        hostApi = "^1"
    }
}

buildConfig {
    packageName("com.typewritermc.realm")
    useKotlinOutput {
        topLevelConstants = true
        internalVisibility = false
    }
    buildConfigField<String>("REALM_VERSION", provider { "${project.version}" })
    buildConfigField<String>("SURREALDB_SERVER_VERSION", libs.versions.surrealdb.server)
    buildConfigField<String>("SURREALDB_EMBEDDED_VERSION", libs.versions.surrealdb.embedded)
}

val verifyPatchIndex =
    tasks.register("verifyPatchIndex") {
        group = "verification"
        description = "Verifies that the patch index matches the packaged patch files"

        val patchesDirectory = file("src/main/resources/schema/patches")
        val indexFile = patchesDirectory.resolve("_index.txt")
        inputs.dir(patchesDirectory)

        doLast {
            val indexedPatches = indexFile.readLines().map(String::trim).filter(String::isNotEmpty)
            val packagedPatches =
                patchesDirectory
                    .listFiles()
                    .orEmpty()
                    .filter { it.isFile && it.extension == "surql" }
                    .map { it.name }
                    .sorted()

            check(indexedPatches == packagedPatches) {
                "Patch index must list every packaged patch once and in ascending order"
            }
        }
    }

val verifyRealmSchemaIndex =
    tasks.register("verifyRealmSchemaIndex") {
        group = "verification"
        description = "Verifies that the Realm schema index lists every packaged schema resource"

        val schemaDirectory = file("src/main/resources/schema/realm")
        val indexFile = schemaDirectory.resolve("_index.txt")
        inputs.dir(schemaDirectory)

        doLast {
            val indexedResources = indexFile.readLines().map(String::trim).filter(String::isNotEmpty)
            val packagedResources =
                schemaDirectory
                    .walkTopDown()
                    .filter { it.isFile && it.extension == "surql" }
                    .map { it.relativeTo(schemaDirectory).invariantSeparatorsPath }
                    .toSet()

            check(indexedResources.size == indexedResources.distinct().size) {
                "Realm schema index must not contain duplicate resources"
            }
            check(indexedResources.toSet() == packagedResources) {
                "Realm schema index must list every packaged schema resource exactly once"
            }
        }
    }

tasks.processResources {
    dependsOn(verifyPatchIndex, verifyRealmSchemaIndex)
}

val verifyLoaderManagedArtifact =
    tasks.register("verifyLoaderManagedArtifact") {
        group = "verification"
        description = "Verifies that Realm is packaged only as a loader managed deployment"
        val realmJar = tasks.named<Jar>("shadowJar").flatMap { it.archiveFile }
        dependsOn(realmJar)
        inputs.file(realmJar)

        doLast {
            JarFile(realmJar.get().asFile).use { archive ->
                check(archive.manifest?.mainAttributes?.getValue(Attributes.Name.MAIN_CLASS) == null) {
                    "Realm must not declare a process entry point"
                }
                check(archive.getEntry("com/typewritermc/realm/RealmMain.class") == null) {
                    "Realm must not package a direct main class"
                }
                check(archive.getEntry("com/typewritermc/realm/DefaultRealmRuntimeFactory.class") != null) {
                    "Realm must package its loader managed runtime factory"
                }
            }
        }
    }

tasks.check {
    dependsOn(verifyLoaderManagedArtifact)
}
