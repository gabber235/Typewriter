import org.gradle.api.GradleException
import org.gradle.api.provider.Provider
import org.gradle.api.provider.ProviderFactory
import org.gradle.process.ProcessExecutionException
import xyz.jpenilla.runpaper.task.RunServer
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.Base64

plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("xyz.jpenilla.run-paper") version "3.0.1"
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
    testImplementation(libs.kotlin.coroutines.test)
}

runPaper {
    disablePluginJarDetection()
}

private fun RunServer.configurePaperRuntime(configurationFile: String) {
    minecraftVersion("26.2")
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

private class RealmDatabaseCredentials(
    val username: String,
    val password: String,
)

private val realmDatabaseCredentialsCommand =
    listOf(
        "kubectl",
        "get",
        "secret",
        "surrealdb-credentials-realm-runtime",
        "--namespace",
        "typewriter",
        "--output",
        """jsonpath={.data.username}{"\n"}{.data.password}""",
    )

private fun ProviderFactory.realmDatabaseCredentials(): Provider<RealmDatabaseCredentials> {
    val kubectl =
        exec {
            isIgnoreExitValue = true
            commandLine(realmDatabaseCredentialsCommand)
        }

    return kubectl.result.zip(
        kubectl.standardOutput.asText.zip(kubectl.standardError.asText) { standardOutput, standardError ->
            standardOutput to standardError
        },
    ) { result, output ->
        val (standardOutput, standardError) = output
        require(result.exitValue == 0) {
            buildString {
                appendLine("Unable to load the Kubernetes Realm database credentials.")
                appendLine("Expected Secret: typewriter/surrealdb-credentials-realm-runtime")
                appendLine(
                    "Apply the Typewriter SurrealDB tenant policy and " +
                        "backend/_clusters/local/surrealdb-credentials-realm-runtime.yaml.",
                )
                if (standardError.isNotBlank()) {
                    append("kubectl: ")
                    append(standardError.trim())
                }
            }.trim()
        }

        val values = standardOutput.lineSequence().filter(String::isNotBlank).toList()
        require(values.size == 2) {
            "Realm database Secret must contain username and password"
        }
        RealmDatabaseCredentials(
            username = values[0].decodeBase64(),
            password = values[1].decodeBase64(),
        )
    }
}

private fun String.decodeBase64(): String = Base64.getDecoder().decode(this).decodeToString()

private fun ProcessExecutionException.withRealmDatabaseCredentialsContext(): GradleException =
    GradleException(
        buildString {
            appendLine("Unable to start kubectl while loading the Kubernetes Realm database credentials.")
            appendLine("Command: ${realmDatabaseCredentialsCommand.joinToString(" ")}")
            appendLine("Working directory: ${System.getProperty("user.dir")}")
            appendLine("PATH: ${System.getenv("PATH").orEmpty()}")
            append("Cause: ${generateSequence<Throwable>(this@withRealmDatabaseCredentialsContext) { it.cause }.last().message}")
        },
        this,
    )

tasks.runServer {
    configurePaperRuntime("local.properties")
}

private val realmDatabaseCredentials = providers.realmDatabaseCredentials()

tasks.register<RunServer>("runServerKubernetes") {
    group = "run paper"
    description = "Run a Paper server using the local Kubernetes Realm database."
    configurePaperRuntime("local-kubernetes.properties")
    doFirst {
        val credentials =
            try {
                realmDatabaseCredentials.get()
            } catch (failure: ProcessExecutionException) {
                throw failure.withRealmDatabaseCredentialsContext()
            }
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
