import java.util.jar.Attributes
import java.util.jar.JarFile

plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    alias(libs.plugins.gradle.buildconfig)
    `java-test-fixtures`
}

/*
 * The route fixture extension reaches the tests twice. The provider loader reads the whole JAR as an extension
 * artifact (its path arrives as a system property) and defines the generated providers it indexes itself, while the
 * test classpath holds the fixture types the tests construct. A generated capability provider calls a private
 * sibling class the index does not name, so the loader asks its parent for that sibling; were the sibling on the
 * test classpath, the two would sit in one package across two class loaders and the call would fail with
 * IllegalAccessError. The test classpath therefore gets the JAR without its capability providers, the same way a
 * deployed extension is invisible to the host class loader.
 */
val routeFixtureExtension by configurations.creating {
    isCanBeConsumed = false
    attributes { attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage.JAVA_RUNTIME)) }
}

val routeFixtureClasses =
    tasks.register<Jar>("routeFixtureClasses") {
        archiveFileName = "realm-route-fixture-classes.jar"
        destinationDirectory = layout.buildDirectory.dir("route-fixtures")
        from(provider { zipTree(routeFixtureExtension.singleFile) }) { exclude("**/*CapabilityProvider*.class") }
    }

tasks.test {
    inputs.files(routeFixtureExtension)
    jvmArgumentProviders += CommandLineArgumentProvider { listOf("-Dtypewriter.realm.routeFixtures=${routeFixtureExtension.singleFile}") }
}

dependencies {
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation(libs.kotlin.coroutines.core)
    implementation(libs.logback)
    implementation(project(":internal-utils"))
    implementation(project(":telemetry"))
    implementation(project(":messaging"))
    implementation(project(":protocol-transport"))
    implementation(project(":file-transfer"))
    imprintHostApi(project(":loader-api"))
    imprintPlatformApi(project(":typewriter-api"))
    implementation(project(":engine-api"))
    implementation(libs.surrealdb.java.sdk)
    implementation(libs.kotlin.serialize.json)

    testFixturesApi(project(":typewriter-test-kit"))
    testFixturesImplementation(libs.surrealdb.java.sdk)
    testFixturesImplementation(libs.kotest.assertions)

    testImplementation(testFixtures(project(":messaging")))
    testImplementation(testFixtures(project(":file-transfer")))
    testImplementation(testFixtures(project(":telemetry")))
    testImplementation(testFixtures(project(":internal-utils")))
    testImplementation(project(":loader-api"))
    // The extension JAR itself: the tests load it as an extension artifact, and its classes live in its common part.
    testCompileOnly(project(":realm-route-fixtures")) {
        attributes { attribute(LibraryElements.LIBRARY_ELEMENTS_ATTRIBUTE, objects.named(LibraryElements.JAR)) }
    }
    routeFixtureExtension(project(":realm-route-fixtures")) {
        isTransitive = false
        attributes { attribute(LibraryElements.LIBRARY_ELEMENTS_ATTRIBUTE, objects.named(LibraryElements.JAR)) }
    }
    testRuntimeOnly(files(routeFixtureClasses))
    testImplementation(libs.kotlin.coroutines.test)
    testImplementation(libs.kotest.property)
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
