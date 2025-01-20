import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
import org.jetbrains.kotlin.util.capitalizeDecapitalize.capitalizeAsciiOnly

plugins {
    kotlin("jvm") version "2.0.21"
    id("io.github.goooler.shadow") version "8.1.7" apply false
    id("com.typewritermc.module-plugin") apply false
    `maven-publish`
}

allprojects {
    apply(plugin = "java")
    apply(plugin = "kotlin")

    repositories {
        // Required
        mavenCentral()
    }

    val targetJavaVersion = 21
    java {
        val javaVersion = JavaVersion.toVersion(targetJavaVersion)
        sourceCompatibility = javaVersion
        targetCompatibility = javaVersion
        toolchain.languageVersion.set(JavaLanguageVersion.of(targetJavaVersion))
    }
    kotlin {
        jvmToolchain(targetJavaVersion)
    }
}


subprojects {
    group = "com.typewritermc"
    version = file("../../version.txt").readText().trim().substringBefore("-beta")

    apply(plugin = "io.github.goooler.shadow")
    apply(plugin = "com.typewritermc.module-plugin")
    apply<MavenPublishPlugin>()

    tasks.withType<ShadowJar> {
        exclude("kotlin/**")
        exclude("META-INF/maven/**")
        // Important: Use the relocated commandapi which is shadowed by the plugin
        relocate("dev.jorel.commandapi", "com.typewritermc.engine.paper.extensions.commandapi") {
            include("dev.jorel.commandapi.**")
        }
    }

    if (!project.name.startsWith("_")) {
        task<ShadowJar>("buildAndMove") {
            group = "build"
            description = "Builds the jar and moves it to the server folder"
            outputs.upToDateWhen { false }

            archiveFileName = "${project.name}.${archiveExtension.get()}"
            destinationDirectory = file("../../server/plugins/Typewriter/extensions")
        }

        task<ShadowJar>("buildRelease") {
            group = "build"
            description = "Builds the jar and renames it"

            archiveFileName = "${project.name}.${archiveExtension.get()}"
            destinationDirectory = file("../../jars/extensions")
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
