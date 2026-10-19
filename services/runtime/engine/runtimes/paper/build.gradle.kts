import com.typewritermc.buildlogic.realmDatabaseCredentials
import xyz.jpenilla.runpaper.task.RunServer
import java.nio.file.Files
import java.nio.file.StandardCopyOption

plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("xyz.jpenilla.run-paper") version "3.1.0"
}

val loaderPlugin =
    configurations.create("loaderPlugin") {
        isTransitive = false
    }
val paperRunDirectory = rootProject.layout.projectDirectory.dir("./build/development/paper")
val paperManualInbox = paperRunDirectory.dir("plugins/Typewriter/artifacts/inbox/manual")
val assembleDevelopmentArtifacts = rootProject.tasks.named("assembleDevelopmentArtifacts")
val stagedPaperArtifactFiles =
    assembleDevelopmentArtifacts.map { task ->
        task.outputs.files.map { artifact -> paperManualInbox.file(artifact.name) }
    }
val stagePaperArtifacts =
    tasks.register("stagePaperArtifacts") {
        group = "typewriter"
        description = "Stages canonical artifacts in the local Paper loader inbox."
        dependsOn(assembleDevelopmentArtifacts)
        inputs.files(assembleDevelopmentArtifacts.map { it.outputs.files })
        outputs.files(stagedPaperArtifactFiles)
        doLast {
            val target = paperManualInbox.asFile.also(File::mkdirs)
            assembleDevelopmentArtifacts.get().outputs.files.forEach { source ->
                val temporary = target.resolve(".${source.name}.partial")
                source.copyTo(temporary, overwrite = true)
                Files.move(
                    temporary.toPath(),
                    target.resolve(source.name).toPath(),
                    StandardCopyOption.ATOMIC_MOVE,
                    StandardCopyOption.REPLACE_EXISTING,
                )
            }
        }
    }

dependencies {
    imprintEngineCore(project(":engine-core"))
    imprintHostApi(project(":loader-api"))
    imprintPlatformApi(project(":typewriter-api"))
    loaderPlugin(project(":loader-distribution"))
}

runPaper {
    disablePluginJarDetection()
}

private fun RunServer.configurePaperRuntime(configurationFile: String) {
    minecraftVersion("26.3")
    build(200)
    javaLauncher.set(
        javaToolchains.launcherFor {
            languageVersion.set(JavaLanguageVersion.of(25))
        },
    )
    runDirectory.set(paperRunDirectory)
    pluginJars.from(loaderPlugin)
    dependsOn(stagePaperArtifacts)
    environment(
        "TYPEWRITER_CONFIG_FILE",
        rootProject.layout.projectDirectory
            .file("runtime/config/$configurationFile")
            .asFile.absolutePath,
    )
}

tasks.runServer {
    configurePaperRuntime("local.properties")
}

private val realmDatabaseCredentials = providers.realmDatabaseCredentials()

tasks.register<RunServer>("runServerKubernetes") {
    group = "run paper"
    description = "Run a Paper server using the local Kubernetes Realm database."
    configurePaperRuntime("local-kubernetes.properties")
    doFirst {
        val credentials = realmDatabaseCredentials.get()
        environment("REALM_DB_USERNAME", credentials.username)
        environment("REALM_DB_PASSWORD", credentials.password)
    }
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
