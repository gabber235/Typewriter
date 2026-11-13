import groovy.json.JsonOutput

// The verification client: a Fabric mod the game pool launches with plain `java`, never `runClient`.
plugins {
    alias(libs.plugins.fabric.loom)
    kotlin("jvm")
    id("de.infix.testBalloon")
}

repositories {
    mavenCentral()
}

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(25))
}

kotlin {
    jvmToolchain(25)
}

dependencies {
    minecraft(libs.minecraft)
    implementation(libs.fabric.loader)
    implementation(libs.fabric.api)
    implementation(project(":playtest-wire"))
    testImplementation(libs.bundles.basic.test)
}

loom {
    runs.named("client") { runDir = "build/run-gradle" }
}

// A Gradle run would open a game window on the developer's machine; the pool launches the client.
tasks.named("runClient") { enabled = false }

// Writes what `runClient` would execute, so the pool launches the client without Gradle. Values are
// read from the task object, never mapped from its provider: a provider mapped from `runClient`
// makes it a dependency and Gradle would start the client.
abstract class WriteClientLaunch : DefaultTask() {
    @get:Input abstract val mainClass: Property<String>

    @get:Classpath abstract val classpath: ConfigurableFileCollection

    @get:Input abstract val jvmArgs: ListProperty<String>

    @get:Input abstract val args: ListProperty<String>

    @get:OutputFile abstract val launch: RegularFileProperty

    @TaskAction
    fun write() {
        val json =
            JsonOutput.toJson(
                mapOf(
                    "main" to mainClass.get(),
                    "classpath" to classpath.files.map { it.absolutePath },
                    "jvmArgs" to jvmArgs.get(),
                    "args" to args.get(),
                ),
            )
        launch.get().asFile.writeText(JsonOutput.prettyPrint(json))
    }
}

val writeClientLaunch =
    tasks.register<WriteClientLaunch>("writeClientLaunch") {
        val run = tasks.named<JavaExec>("runClient").get()
        dependsOn("classes", "downloadAssets", "configureClientLaunch")
        mainClass.set(run.mainClass)
        classpath.from(run.classpath)
        jvmArgs.set(run.allJvmArgs)
        args.set(run.args.orEmpty())
        launch.set(layout.buildDirectory.file("client-launch.json"))
    }

configurations.consumable("playtestClientLaunch") {
    outgoing.artifact(writeClientLaunch.flatMap { it.launch })
}
