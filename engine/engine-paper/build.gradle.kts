import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
import io.papermc.hangarpublishplugin.model.Platforms
import xyz.jpenilla.resourcefactory.paper.PaperPluginYaml
import java.io.ByteArrayOutputStream

plugins {
    id("xyz.jpenilla.resource-factory-paper-convention") version "1.2.0"
    id("io.papermc.hangar-publish-plugin") version "0.1.3"
}

repositories {
    mavenCentral()
    // Floodgate & Geyser
    maven("https://repo.opencollab.dev/main/")
    // PacketEvents
    maven("https://repo.codemc.io/repository/maven-releases/")
    maven("https://repo.codemc.io/repository/maven-snapshots/")
    // PlaceholderAPI
    maven("https://repo.extendedclip.com/content/repositories/placeholderapi/")
    // PaperMC
    maven {
        name = "papermc"
        url = uri("https://repo.papermc.io/repository/maven-public/")
    }
    // EntityLib
    maven("https://maven.evokegames.gg/snapshots")
}

dependencies {
    compileOnlyApi("io.papermc.paper:paper-api:1.21.5-R0.1-SNAPSHOT")

    api(project(":engine-core"))
    api(project(":engine-loader"))

    compileOnlyApi("com.corundumstudio.socketio:netty-socketio:1.7.19") // Keep this on a lower version as the newer version breaks the ping

    api("me.tofaa.entitylib:spigot:+630837f-SNAPSHOT")
    compileOnlyApi("com.github.shynixn.mccoroutine:mccoroutine-bukkit-api:2.22.0")
    compileOnlyApi("com.github.shynixn.mccoroutine:mccoroutine-bukkit-core:2.22.0")

    // Doesn't want to load properly using the spigot api.
    compileOnlyApi("io.ktor:ktor-server-core-jvm:2.3.13")
    compileOnlyApi("io.ktor:ktor-server-netty-jvm:2.3.13")
    compileOnlyApi("org.jetbrains.kotlinx:kotlinx-serialization-core:1.8.1")
    compileOnlyApi("org.bstats:bstats-bukkit:3.1.0")

    val adventureVersion = "4.20.0"
    compileOnlyApi("net.kyori:adventure-api:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-minimessage:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-serializer-plain:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-serializer-legacy:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-serializer-gson:$adventureVersion")

    compileOnlyApi("com.github.retrooper:packetevents-api:2.8.0")
    compileOnlyApi("com.github.retrooper:packetevents-spigot:2.8.0")

    compileOnly("me.clip:placeholderapi:2.11.6")
    compileOnlyApi("org.geysermc.geyser:api:2.7.0-SNAPSHOT")
    compileOnlyApi("org.geysermc.floodgate:api:2.2.4-SNAPSHOT")

    testImplementation("org.mockbukkit.mockbukkit:mockbukkit-v1.21:4.46.3")
}

tasks.withType<ShadowJar> {
    minimize {
        exclude("kotlin/**")
        exclude("org/intellij/**")
        exclude("org/jetbrains/**")
        exclude(dependency("web::"))
    }
}

tasks.register<ShadowJar>("buildAndMove") {
    from(tasks.shadowJar)
    group = "build"
    description = "Builds the jar and moves it to the server folder"
    outputs.upToDateWhen { false }

    destinationDirectory = file("../../server/plugins")
    archiveFileName = "Typewriter.${archiveExtension.get()}"
    manifest.from(tasks.shadowJar.get().manifest)
}

tasks.register<ShadowJar>("buildRelease") {
    from(tasks.shadowJar)
    from("../../app/build/web") {
        into("web")
    }
    group = "build"
    description = "Builds the jar including the flutter web panel"

    outputs.upToDateWhen { false }

    archiveFileName = "Typewriter-${project.version}.${archiveExtension.get()}"
    destinationDirectory = file("../../jars/engine")
    manifest.from(tasks.shadowJar.get().manifest)
}

fun executeGitCommand(vararg command: String): String {
    val byteOut = ByteArrayOutputStream()
    exec {
        commandLine = listOf("git", *command)
        standardOutput = byteOut
    }
    return byteOut.toString(Charsets.UTF_8.name()).trim()
}

fun latestCommitMessage(): String {
    return executeGitCommand("log", "-1", "--pretty=%B")
}

hangarPublish {
    publications.register("plugin") {
        version.set(project.version.toString())
        if (project.version.toString().contains("beta")) {
            channel.set("Beta")
        } else {
            channel.set("Release")
        }

        id.set("Typewriter")
        changelog.set(latestCommitMessage())
        apiKey.set(System.getenv("HANGAR_API_TOKEN"))

        platforms {
            register(Platforms.PAPER) {
                url.set("https://modrinth.com/plugin/typewriter/version/${project.version}")

                val versions: List<String> = (property("paperVersion") as String)
                    .split(",")
                    .map { it.trim() }
                platformVersions.set(versions)

                dependencies {
                    url("PacketEvents", "https://modrinth.com/plugin/packetevents/versions?l=paper") {
                        required.set(true)
                    }
                    hangar("PlaceholderAPI") {
                        required.set(false)
                    }
                    hangar("Floodgate") {
                        required.set(false)
                    }
                }
            }
        }
    }
}

paperPluginYaml {
    name = "Typewriter"
    description = "Next Generation Story Telling Plugin"
    authors = listOf("gabber235")
    website = "https://docs.typewritermc.com"
    version = project.version.toString()

    main = "com.typewritermc.engine.paper.TypewriterPaperPlugin"
    apiVersion = "1.21.3"

    foliaSupported = false

    dependencies {
        server("packetevents", load = PaperPluginYaml.Load.AFTER, required = true, joinClasspath = true)
        server("PlaceholderAPI", load = PaperPluginYaml.Load.AFTER, required = false, joinClasspath = true)
        server("floodgate", load = PaperPluginYaml.Load.AFTER, required = false, joinClasspath = true)
    }

    loader = "com.typewritermc.engine.paper.TypewriterPaperLoader"
}