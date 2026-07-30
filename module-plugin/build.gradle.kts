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
    `java-gradle-plugin`
    id("com.gradle.plugin-publish") version "2.1.1"
    id("com.google.devtools.ksp") version "2.3.8"
    kotlin("plugin.serialization") version "2.3.20" apply false
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

group = "com.typewritermc.module-plugin"
version = "2.2.0"

val engineVersion = typewriterVersion.substringBefore("-beta")

subprojects {
    group = rootProject.group
    version = rootProject.version
}

allprojects {
    apply(plugin = "kotlin")
    apply(plugin = "kotlinx-serialization")
    apply(plugin = "maven-publish")

    repositories {
        mavenCentral()
        maven("https://plugins.gradle.org/m2/")
    }

    dependencies {
        implementation(kotlin("stdlib"))
        implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.10.0")
        implementation("com.google.devtools.ksp:symbol-processing-gradle-plugin:2.3.8")
        implementation("com.google.devtools.ksp:symbol-processing-api:2.3.8")

        implementation("com.typewritermc:engine-core:$engineVersion")


        testImplementation(kotlin("test"))
        val kotestVersion = "6.1.11"
        testImplementation("io.kotest:kotest-runner-junit5:$kotestVersion")
        testImplementation("io.kotest:kotest-assertions-core:$kotestVersion")
        testImplementation("io.kotest:kotest-property:$kotestVersion")
    }

    tasks.test {
        useJUnitPlatform()
    }
    kotlin {
        jvmToolchain(typewriterJavaVersion)
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
                version = project.version.toString()
                artifactId = project.name

                from(components["kotlin"])
            }
        }
    }
}


dependencies {
    implementation(gradleApi())
    api(project(":api"))
    api(project(":extension-processor"))

    testImplementation(kotlin("test"))
}


gradlePlugin {
    plugins {
        create("typewriterModulePlugin") {
            id = "com.typewritermc.module-plugin"
            implementationClass = "com.typewritermc.TypewriterModulePlugin"
        }
    }
}

tasks.register("generateResources") {
    val propFile = layout.buildDirectory.file("generated/typewriter-module-plugin.properties").get().asFile
    outputs.file(propFile)

    doLast {
        propFile.parentFile.mkdirs()
        propFile.writeText("version=$version")
    }
}

tasks.named<ProcessResources>("processResources") {
    from(tasks["generateResources"])
}
