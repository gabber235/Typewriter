import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("java")
    kotlin("jvm") version "2.3.20"
    id("java-library")
    `maven-publish`
    id("com.gradleup.shadow") version "9.4.1" apply false
}

group = "com.typewritermc"
val versionFile = if (file("version.txt").exists()) file("version.txt") else file("../version.txt")
version = versionFile.readText().trim()

allprojects {
    apply(plugin = "java")
    apply(plugin = "kotlin")

    repositories {
        mavenCentral()
        // PacketEvents
        maven("https://repo.codemc.io/repository/maven-snapshots/")
    }


    tasks.test {
        useJUnitPlatform()
    }
    kotlin {
        jvmToolchain(25)
    }
    tasks.withType(KotlinCompile::class.java) {
        compilerOptions.freeCompilerArgs.add("-Xcontext-parameters")
    }
}

subprojects {
    apply(plugin = "com.gradleup.shadow")
    apply(plugin = "java-library")
    apply(plugin = "maven-publish")

    group = rootProject.group
    version = rootProject.version

    dependencies {
        api("io.insert-koin:koin-core:4.2.1")
        compileOnly("com.google.code.gson:gson:2.13.2")

        compileOnlyApi(kotlin("stdlib"))
        compileOnlyApi(kotlin("reflect"))
        compileOnlyApi("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")

        val kotestVersion = "6.1.11"
        testImplementation("io.kotest:kotest-runner-junit5:$kotestVersion")
        testImplementation("io.kotest:kotest-framework-engine:$kotestVersion")
        testImplementation("io.kotest:kotest-assertions-core:$kotestVersion")
        testImplementation("io.kotest:kotest-property:$kotestVersion")
        testImplementation("io.mockk:mockk:1.14.9")
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
