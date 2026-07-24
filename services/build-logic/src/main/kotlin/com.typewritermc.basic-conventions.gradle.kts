plugins {
    kotlin("jvm")
    id("de.infix.testBalloon")
}

group = "com.typewritermc"

repositories {
    mavenCentral()
}

kotlin {
    jvmToolchain(21)
    compilerOptions {
        freeCompilerArgs.add("-opt-in=kotlin.RequiresOptIn")
    }
}

val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")
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
