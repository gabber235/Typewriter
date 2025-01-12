import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
import org.jetbrains.kotlin.util.capitalizeDecapitalize.capitalizeAsciiOnly

plugins {
    kotlin("jvm") version "2.0.21"
    id("io.github.goooler.shadow") version "8.1.7"
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
        tasks.register("buildAndMove") {
            dependsOn("shadowJar")

            group = "build"
            description = "Builds the jar and moves it to the server folder"
            outputs.upToDateWhen { false }

            // Move the jar from the build/libs folder to the server/plugins folder
            doLast {
                val jar = file("build/libs/%s-%s-all.jar".format(project.name, project.version))
                val server =
                    file("../../server/plugins/Typewriter/extensions/%s.jar".format(project.name.capitalizeAsciiOnly()))
                jar.copyTo(server, overwrite = true)
            }
        }

        tasks.register("buildRelease") {
            onlyIf { !project.name.startsWith("_") }
            dependsOn("shadowJar")
            group = "build"
            description = "Builds the jar and renames it"

            doLast {
                // Rename the jar to remove the version and -all
                val jar = file("build/libs/%s-%s-all.jar".format(project.name, project.version))
                jar.renameTo(file("build/libs/%s.jar".format(project.name)))
                file("build/libs/%s-%s.jar".format(project.name, project.version)).delete()
            }
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
