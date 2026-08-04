plugins {
    kotlin("jvm")
    id("de.infix.testBalloon")
    id("org.jlleitschuh.gradle.ktlint")
    id("dev.detekt")
}

group = "com.typewritermc"

repositories {
    mavenCentral()
}

val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")
val servicesDirectory =
    generateSequence(rootProject.projectDir) { it.parentFile }
        .first { File(it, "build-logic").isDirectory && File(it, "libs.versions.toml").isFile }

detekt {
    buildUponDefaultConfig = false
    allRules = false
    config.setFrom(File(servicesDirectory, "config/detekt/observability.yml"))
}

ktlint {
    version.set(libs.findVersion("ktlint").get().requiredVersion)
    filter {
        exclude("**/skirout/**")
    }
}

kotlin {
    jvmToolchain(21)
    compilerOptions {
        freeCompilerArgs.add("-Xcontext-parameters")
        freeCompilerArgs.add("-opt-in=kotlin.RequiresOptIn")
    }
}

dependencies {
    testImplementation(libs.findBundle("basic-test").get())
}

tasks.withType<Test> {
    useJUnitPlatform()
}

fun String.runCommand(): String? = try {
    ProcessBuilder(*split(" ").toTypedArray())
        .redirectOutput(ProcessBuilder.Redirect.PIPE)
        .redirectError(ProcessBuilder.Redirect.PIPE)
        .start()
        .apply { waitFor(10, TimeUnit.SECONDS) }
        .inputStream.bufferedReader().readText().trim()
} catch (_: Exception) {
    null
}
