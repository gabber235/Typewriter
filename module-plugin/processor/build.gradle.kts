import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.google.devtools.ksp") version "2.0.21-1.0.28"
}

repositories {
    maven("https://repo.codemc.io/repository/maven-snapshots/")
}

dependencies {
    api("com.google.code.gson:gson:2.13.1")
    api(project(":api"))

    api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
}

tasks.withType(KotlinCompile::class.java) {
    compilerOptions.freeCompilerArgs.add("-Xcontext-receivers")
}