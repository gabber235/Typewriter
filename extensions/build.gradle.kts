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
