import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.google.devtools.ksp") version "2.2.10-2.0.2"
}

repositories {
    maven("https://repo.codemc.io/repository/maven-snapshots/")
}

dependencies {
    implementation(project(":processor"))

    val ktorVersion = "2.3.12"
    implementation("io.ktor:ktor-client-core:$ktorVersion")
    implementation("io.ktor:ktor-client-cio:$ktorVersion")
}

tasks.withType(KotlinCompile::class.java) {
    compilerOptions.freeCompilerArgs.add("-Xcontext-parameters")
}