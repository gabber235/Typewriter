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
        exclude { it.file.invariantSeparatorsPath.contains("/skirout/") }
        exclude { it.file.invariantSeparatorsPath.contains("/generated/ksp/") }
    }
}

kotlin {
    jvmToolchain(21)
    compilerOptions {
        freeCompilerArgs.add("-opt-in=kotlin.RequiresOptIn")
        freeCompilerArgs.add("-Xcontext-parameters")
    }
}

dependencies {
    testImplementation(libs.findBundle("basic-test").get())
}

tasks.withType<Test> {
    useJUnitPlatform()
    // CI keeps only the console, so a failure must print its full cause chain there.
    testLogging {
        events(org.gradle.api.tasks.testing.logging.TestLogEvent.FAILED)
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        showCauses = true
        showStackTraces = true
    }
}
