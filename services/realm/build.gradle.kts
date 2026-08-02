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
    implementation("com.typewritermc:service-communicator-skir")
    implementation(platform(libs.opentelemetry.bom))
    implementation(libs.opentelemetry.sdk)
    implementation(libs.opentelemetry.exporter.logging)
    implementation(libs.opentelemetry.exporter.otlp)
    implementation(libs.opentelemetry.semconv)

    implementation(libs.jline)
    implementation(libs.clikt)
    implementation(libs.surrealdb)
    
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
