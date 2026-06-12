import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
import io.papermc.hangarpublishplugin.model.Platforms
import xyz.jpenilla.resourcefactory.paper.PaperPluginYaml

plugins {
    id("xyz.jpenilla.resource-factory-paper-convention") version "1.3.1"
    id("io.papermc.hangar-publish-plugin") version "0.1.4"
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
    maven {
        name = "TypewriterMC"
        url = uri("https://maven.typewritermc.com/external")
    }
}

dependencies {
    val paperVersion = "1.21.11-R0.1-SNAPSHOT"
    compileOnlyApi("io.papermc.paper:paper-api:$paperVersion")

    api(project(":engine-core"))
    api(project(":engine-loader"))

    compileOnlyApi("com.corundumstudio.socketio:netty-socketio:1.7.19") // Keep this on a lower version as the newer version breaks the ping

    api("io.github.tofaa2:spigot:3.1.0-SNAPSHOT")
    compileOnlyApi("com.github.shynixn.mccoroutine:mccoroutine-bukkit-api:2.22.0")
    compileOnlyApi("com.github.shynixn.mccoroutine:mccoroutine-bukkit-core:2.22.0")

    // Doesn't want to load properly using the spigot api.
    compileOnlyApi("io.ktor:ktor-server-core-jvm:2.3.13")
    compileOnlyApi("io.ktor:ktor-server-netty-jvm:2.3.13")
    compileOnlyApi("org.jetbrains.kotlinx:kotlinx-serialization-core:1.11.0")
    compileOnlyApi("org.bstats:bstats-bukkit:3.2.1")

    val adventureVersion = "5.1.1"
    compileOnlyApi("net.kyori:adventure-api:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-minimessage:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-serializer-plain:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-serializer-legacy:$adventureVersion")
    compileOnlyApi("net.kyori:adventure-text-serializer-gson:$adventureVersion")

    compileOnlyApi("com.github.retrooper:packetevents-api:2.11.1")
    compileOnlyApi("com.github.retrooper:packetevents-spigot:2.11.1")

    compileOnly("me.clip:placeholderapi:2.12.2")
    compileOnlyApi("org.geysermc.geyser:api:2.9.5-SNAPSHOT")
    compileOnlyApi("org.geysermc.floodgate:api:2.2.5-SNAPSHOT")

    testImplementation("io.papermc.paper:paper-api:$paperVersion")
    testImplementation("org.mockbukkit.mockbukkit:mockbukkit-v1.21:4.108.0")
}

tasks.withType<ShadowJar> {
    minimize {
        exclude("kotlin/**")
        exclude("org/intellij/**")
        exclude("org/jetbrains/**")
        exclude(dependency("web::"))
    }
}

tasks.register<Copy>("buildAndMove") {
    dependsOn(tasks.shadowJar)
    from(tasks.shadowJar.flatMap { it.archiveFile })
    group = "build"
    description = "Builds the jar and moves it to the server folder"
    outputs.upToDateWhen { false }

    into(file("../../server/plugins"))
    rename { "Typewriter.jar" }
}

tasks.register<Jar>("buildRelease") {
    dependsOn(tasks.shadowJar)
    from(zipTree(tasks.shadowJar.flatMap { it.archiveFile }))
    from("../../app/build/web") {
        into("web")
    }
    group = "build"
    description = "Builds the jar including the flutter web panel"

    outputs.upToDateWhen { false }

    archiveFileName = "Typewriter-${project.version}.jar"
    destinationDirectory.set(file("../../jars/engine"))
    manifest.from(tasks.shadowJar.get().manifest)
}

fun executeGitCommand(vararg command: String): String {
    return providers.exec {
        commandLine("git", *command)
    }.standardOutput.asText.get().trim()
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
        server("packetevents", load = PaperPluginYaml.Load.BEFORE, required = true, joinClasspath = true)
        server("PlaceholderAPI", load = PaperPluginYaml.Load.BEFORE, required = false, joinClasspath = true)
        server("floodgate", load = PaperPluginYaml.Load.BEFORE, required = false, joinClasspath = true)
    }

    loader = "com.typewritermc.engine.paper.TypewriterPaperLoader"
}
