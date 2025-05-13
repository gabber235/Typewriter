import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar

plugins {
    kotlin("jvm") version "2.0.21"
    id("io.github.goooler.shadow") version "8.1.8" apply false
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
        exclude("org/intellij/**")
        exclude("org/jetbrains/**")
        exclude("META-INF/maven/**")
    }

    if (!project.name.startsWith("_")) {
        task<ShadowJar>("buildAndMove") {
            from(tasks.named("shadowJar"))
            group = "build"
            description = "Builds the jar and moves it to the server folder"
            outputs.upToDateWhen { false }

            archiveFileName = "${project.name}.${archiveExtension.get()}"
            destinationDirectory = file("../../server/plugins/Typewriter/extensions")
        }

        task<ShadowJar>("buildRelease") {
            from(tasks.named("shadowJar"))
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
