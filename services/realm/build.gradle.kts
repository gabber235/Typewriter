plugins {
    id("com.typewritermc.basic-conventions")
    application
    alias(libs.plugins.kotlin.serialize)
    alias(libs.plugins.gradle.buildconfig)
}

version = "1000.0.0"

application {
    mainClass.set("com.typewritermc.realm.RealmMain")
}

dependencies {
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation(libs.kotlin.coroutines.core)
    implementation(libs.logback)
    implementation(libs.kotlin.serialize.cbor)
    implementation(libs.kotlin.serialize.json)
    implementation("com.typewritermc:service-utils")
    implementation("com.typewritermc:service-telemetry-koin")
    implementation("com.typewritermc:service-registrar-koin")
    implementation("com.typewritermc:service-registrar-console")
    implementation("com.typewritermc:service-communicator-skir")
    implementation(platform(libs.opentelemetry.bom))
    implementation(libs.opentelemetry.sdk)
    implementation(libs.opentelemetry.exporter.logging)
    implementation(libs.opentelemetry.exporter.otlp)
    implementation(libs.opentelemetry.semconv)

    implementation(libs.jline)
    implementation(libs.clikt)
    implementation(libs.surrealdb.java.sdk)

    testImplementation("com.typewritermc:service-communicator-testing")
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.mockk)
    testImplementation(libs.kotlin.coroutines.test)
}

buildConfig {
    packageName("com.typewritermc.realm")
    useKotlinOutput {
        topLevelConstants = true
        internalVisibility = false
    }
    buildConfigField<String>("REALM_VERSION", provider { "${project.version}" })
    buildConfigField<String>("SURREALDB_SERVER_VERSION", libs.versions.surrealdb.server)
}

val verifyPatchIndex = tasks.register("verifyPatchIndex") {
    group = "verification"
    description = "Verifies that the patch index matches the packaged patch files"

    val patchesDirectory = file("src/main/resources/schema/patches")
    val indexFile = patchesDirectory.resolve("_index.txt")
    inputs.dir(patchesDirectory)

    doLast {
        val indexedPatches = indexFile.readLines().map(String::trim).filter(String::isNotEmpty)
        val packagedPatches = patchesDirectory.listFiles()
            .orEmpty()
            .filter { it.isFile && it.extension == "surql" }
            .map { it.name }
            .sorted()

        check(indexedPatches == packagedPatches) {
            "Patch index must list every packaged patch once and in ascending order"
        }
    }
}

val verifyRealmSchemaIndex = tasks.register("verifyRealmSchemaIndex") {
    group = "verification"
    description = "Verifies that the Realm schema index lists every packaged schema resource"

    val schemaDirectory = file("src/main/resources/schema/realm")
    val indexFile = schemaDirectory.resolve("_index.txt")
    inputs.dir(schemaDirectory)

    doLast {
        val indexedResources = indexFile.readLines().map(String::trim).filter(String::isNotEmpty)
        val packagedResources = schemaDirectory.walkTopDown()
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
