plugins {
    id("java")
    kotlin("jvm") version libs.versions.kotlin.get()
    id("java-library")
    `maven-publish`
    alias(libs.plugins.shadow) apply false
    alias(libs.plugins.kotlin.serialization) version libs.versions.kotlin.get() apply false
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
        jvmToolchain(21)
    }
}

subprojects {
    apply(plugin = rootProject.libs.plugins.shadow.get().pluginId)
    apply(plugin = rootProject.libs.plugins.kotlin.serialization.get().pluginId)
    apply(plugin = "java-library")
    apply(plugin = "maven-publish")

    group = rootProject.group
    version = rootProject.version

    dependencies {
        api(rootProject.libs.koin)

        api(rootProject.libs.kotlin.serialization)
        //compileOnly("com.google.code.gson:gson:2.13.1")

        compileOnlyApi(kotlin("stdlib", rootProject.libs.versions.kotlin.get()))
        compileOnlyApi(kotlin("reflect", rootProject.libs.versions.kotlin.get()))
        compileOnlyApi(rootProject.libs.kotlinx.coroutines)

        testImplementation(rootProject.libs.bundles.kotest)
        testImplementation(rootProject.libs.mockk)
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