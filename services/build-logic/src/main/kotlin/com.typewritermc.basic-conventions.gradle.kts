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
    config.setFrom(
        File(servicesDirectory, "config/detekt/observability.yml"),
        File(servicesDirectory, "config/detekt/structure.yml"),
    )
    // One baseline per project: each project's baseline task rewrites its whole file.
    baseline = File(servicesDirectory, "config/detekt/baselines/${project.name}.xml")
}

// Generated sources are not reviewed and change on every generation, so no baseline can hold them.
tasks.withType<dev.detekt.gradle.Detekt>().configureEach {
    exclude { it.file.invariantSeparatorsPath.contains("/skirout/") }
}
tasks.withType<dev.detekt.gradle.DetektCreateBaselineTask>().configureEach {
    exclude { it.file.invariantSeparatorsPath.contains("/skirout/") }
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
}
