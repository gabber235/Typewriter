import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.google.devtools.ksp") version "2.3.6"
}

repositories {
    maven("https://repo.codemc.io/repository/maven-snapshots/")
}

dependencies {
    api("com.google.code.gson:gson:2.13.2")
    api(project(":api"))

    api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
}

tasks.withType(KotlinCompile::class.java) {
    compilerOptions.freeCompilerArgs.add("-Xcontext-parameters")
}
