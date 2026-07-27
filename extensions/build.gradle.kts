import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
import org.tomlj.Toml

buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.tomlj:tomlj:1.1.1")
    }
}

plugins {
    kotlin("jvm") version "2.3.20"
    id("com.gradleup.shadow") version "9.4.1" apply false
    id("com.typewritermc.module-plugin") apply false
    `maven-publish`
}

val typewriterSettingsFile = rootProject.file("../settings.toml")
val typewriterSettings = Toml.parse(typewriterSettingsFile.toPath())

if (typewriterSettings.hasErrors()) {
    error(typewriterSettings.errors().joinToString("\n"))
}

val configuredTypewriterVersion = typewriterSettings.getString("version") ?: error("Missing version in settings.toml")
val configuredTypewriterJavaVersion = typewriterSettings.getLong("java")?.toInt() ?: error("Missing java in settings.toml")
val typewriterVersion = providers.gradleProperty("typewriter.version").getOrElse(configuredTypewriterVersion)
val typewriterJavaVersion = providers.gradleProperty("typewriter.java")
    .map(String::toInt)
    .getOrElse(configuredTypewriterJavaVersion)
val typewriterEngineVersion = typewriterVersion

rootProject.extra["typewriterEngineVersion"] = typewriterEngineVersion

allprojects {
    apply(plugin = "java")
    apply(plugin = "kotlin")

    repositories {
        // Required
        mavenCentral()
        maven {
            name = "JitPack"
            url = uri("https://jitpack.io")
        }
    }

    java {
        val javaVersion = JavaVersion.toVersion(typewriterJavaVersion)
        sourceCompatibility = javaVersion
        targetCompatibility = javaVersion
        toolchain.languageVersion.set(JavaLanguageVersion.of(typewriterJavaVersion))
    }
    kotlin {
        jvmToolchain(typewriterJavaVersion)
    }
}


subprojects {
    group = "com.typewritermc"
    version = typewriterVersion.substringBefore("-beta")

    apply(plugin = "com.gradleup.shadow")
    apply(plugin = "com.typewritermc.module-plugin")
    apply<MavenPublishPlugin>()

    dependencies {
        // The server and the engine are compileOnly, as an extension is handed both once it runs. A test
        // has nothing handing them over, so it asks for them itself. These versions follow the ones the
        // engine builds against.
        testImplementation("com.typewritermc:engine-paper:$typewriterEngineVersion")
        testImplementation("io.papermc.paper:paper-api:1.21.11-R0.1-SNAPSHOT")
        testImplementation("com.github.retrooper:packetevents-spigot:2.13.0")
        testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")

        val kotestVersion = "6.1.11"
        testImplementation("io.kotest:kotest-runner-junit5:$kotestVersion")
        testImplementation("io.kotest:kotest-assertions-core:$kotestVersion")
        testImplementation("io.mockk:mockk:1.14.9")
        testImplementation("org.mockbukkit.mockbukkit:mockbukkit-v1.21:4.108.0")
    }

    tasks.test {
        useJUnitPlatform()
    }

    tasks.withType<ShadowJar> {
        exclude("kotlin/**")
        exclude("org/intellij/**")
        exclude("org/jetbrains/**")
        exclude("META-INF/maven/**")
    }

    if (!project.name.startsWith("_")) {
        tasks.register<Copy>("buildAndMove") {
            dependsOn(tasks.named("shadowJar"))
            from(tasks.named<ShadowJar>("shadowJar").flatMap { it.archiveFile })
            group = "build"
            description = "Builds the jar and moves it to the server folder"
            outputs.upToDateWhen { false }

            into(file("../../server/plugins/Typewriter/extensions"))
            rename { "${project.name}.jar" }
        }

        tasks.register<Copy>("buildRelease") {
            dependsOn(tasks.named("shadowJar"))
            from(tasks.named<ShadowJar>("shadowJar").flatMap { it.archiveFile })
            group = "build"
            description = "Builds the jar and renames it"

            into(file("../../jars/extensions"))
            rename { "${project.name}.jar" }
        }

        tasks.register("releaseSourcesJar", Jar::class) {
            archiveClassifier.set("sources")
            from(sourceSets.main.get().allSource)
        }

        publishing {
            repositories {
                maven {
                    name = "TypewriterReleases"
                    url = uri("https://maven.typewritermc.com/releases")
                    credentials(PasswordCredentials::class)
                    authentication {
                        create<BasicAuthentication>("basic")
                    }
                }
                maven {
                    name = "TypewriterBeta"
                    url = uri("https://maven.typewritermc.com/beta")
                    credentials(PasswordCredentials::class)
                    authentication {
                        create<BasicAuthentication>("basic")
                    }
                }
            }
            publications {
                create<MavenPublication>("maven") {
                    group = project.group
                    // Remove everything after the beta. So 1.0.0-beta-1 becomes 1.0.0
                    version = project.version.toString().substringBefore("-beta")
                    artifactId = project.name

                    from(components["kotlin"])
                    artifact(tasks["shadowJar"])
                    artifact(tasks["releaseSourcesJar"])
                }
            }
        }
    }
}
