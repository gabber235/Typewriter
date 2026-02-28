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
    implementation(libs.logback)
    implementation(libs.kotlin.serialize.cbor)
    implementation(libs.kotlin.serialize.json)
    implementation("com.typewritermc:service-utils")
    implementation("com.typewritermc:service-telemetry")
    implementation("com.typewritermc:service-registrar")
    implementation("com.typewritermc:service-communicator")

    implementation(libs.jline)
    implementation(libs.clikt)
    implementation(libs.surrealdb)
    
    testImplementation(testFixtures("com.typewritermc:service-communicator"))
    testImplementation(testFixtures("com.typewritermc:service-telemetry"))
}

buildConfig {
    packageName("com.typewritermc.realm")
    useKotlinOutput {
        topLevelConstants = true
        internalVisibility = false
    }
    buildConfigField<String>("REALM_VERSION", provider { "${project.version}" })
}

val generatePatchIndex by tasks.registering {
    group = "build"
    description = "Generates _index.txt listing all patch files in order"

    val patchesDir = file("src/main/resources/schema/patches")
    val outputDir = layout.buildDirectory.dir("generated/resources/main/schema/patches")
    val outputFile = outputDir.map { it.file("_index.txt") }

    inputs.dir(patchesDir).optional()
    outputs.file(outputFile)

    doLast {
        val patches = patchesDir.takeIf { it.exists() }
            ?.listFiles { file ->
                file.isFile && file.extension == "surql" && !file.name.startsWith("_")
            }
            ?.sortedBy { it.name }
            ?: emptyList()

        val indexContent = patches.joinToString("\n") { it.name }

        outputFile.get().asFile.apply {
            parentFile.mkdirs()
            writeText(indexContent)
        }

        logger.lifecycle("Generated patch index with ${patches.size} patches")
    }
}

sourceSets {
    main {
        resources {
            srcDir(layout.buildDirectory.dir("generated/resources/main"))
        }
    }
}

tasks.processResources {
    dependsOn(generatePatchIndex)
}