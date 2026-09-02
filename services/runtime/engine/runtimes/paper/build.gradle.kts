plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("xyz.jpenilla.run-paper") version "3.0.1"
}

val loaderPlugin =
    configurations.create("loaderPlugin") {
        isTransitive = false
    }
val paperRunDirectory = rootProject.layout.projectDirectory.dir("../build/development/paper")
val paperDevelopmentInbox = paperRunDirectory.dir("plugins/TypewriterLoader/artifacts/inbox/development")
val assembleDevelopmentArtifacts = rootProject.tasks.named("assembleDevelopmentArtifacts")
val stagePaperDevelopmentArtifacts =
    tasks.register<Sync>("stagePaperDevelopmentArtifacts") {
        group = "typewriter"
        description = "Stages canonical development artifacts for the local Paper loader."
        dependsOn(assembleDevelopmentArtifacts)
        from(assembleDevelopmentArtifacts.map { it.outputs.files.singleFile })
        into(paperDevelopmentInbox)
    }

dependencies {
    imprintEngineCore(project(":engine-core"))
    imprintHostApi(project(":loader-api"))
    loaderPlugin(project(":loader-distribution"))
    testImplementation(libs.kotlin.coroutines.test)
}

runPaper {
    disablePluginJarDetection()
}

tasks.runServer {
    minecraftVersion("26.2")
    javaLauncher.set(
        javaToolchains.launcherFor {
            languageVersion.set(JavaLanguageVersion.of(25))
        },
    )
    runDirectory.set(paperRunDirectory)
    pluginJars.from(loaderPlugin)
    dependsOn(stagePaperDevelopmentArtifacts)
    environment(
        "TYPEWRITER_CONFIG_FILE",
        rootProject.layout.projectDirectory
            .file("runtime/config/local.properties")
            .asFile.absolutePath,
    )
}

typewriter {
    engine {
        id = "typewritermc:paper"
        version = "1.0.0"
        hostApi = "^1"
        implements {
            capability(project(":engine-minecraft"), version = "1.0.0")
        }
    }
}
