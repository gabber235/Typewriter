plugins {
    kotlin("jvm") version "2.3.20"
    `java-gradle-plugin`
    id("com.gradle.plugin-publish") version "2.1.1"
    id("com.google.devtools.ksp") version "2.3.6"
    kotlin("plugin.serialization") version "2.3.20" apply false
    `maven-publish`
}

group = "com.typewritermc.module-plugin"
version = "2.1.0"

val engineVersion = file("../version.txt").readText().trim().substringBefore("-beta")

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
        implementation("com.google.devtools.ksp:symbol-processing-gradle-plugin:2.3.6")
        implementation("com.google.devtools.ksp:symbol-processing-api:2.3.6")

        implementation("com.typewritermc:engine-core:$engineVersion")


        testImplementation(kotlin("test"))
        val kotestVersion = "6.1.10"
        testImplementation("io.kotest:kotest-runner-junit5:$kotestVersion")
        testImplementation("io.kotest:kotest-assertions-core:$kotestVersion")
        testImplementation("io.kotest:kotest-property:$kotestVersion")
    }

    tasks.test {
        useJUnitPlatform()
    }
    kotlin {
        jvmToolchain(25)
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
