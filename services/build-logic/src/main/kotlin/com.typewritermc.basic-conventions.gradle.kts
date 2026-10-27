import com.typewritermc.buildlogic.servicesDirectory

plugins {
    kotlin("jvm")
    id("de.infix.testBalloon")
    id("org.jlleitschuh.gradle.ktlint")
    id("dev.detekt")
    id("org.jetbrains.kotlinx.kover")
}

group = "com.typewritermc"

repositories {
    mavenCentral()
}

val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")

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

// Test fixtures hold the module's setups, fakes and assertions, so like the tests they get the
// test toolkit, the module's implementation dependencies and its internals; the tests see the
// fixtures' internals. Fixtures can then drive internal types without widening production
// visibility for tests.
pluginManager.withPlugin("java-test-fixtures") {
    configurations.named("testFixturesImplementation") { extendsFrom(configurations.getByName("implementation")) }
    dependencies {
        "testFixturesImplementation"(libs.findBundle("basic-test").get())
    }
    val compilations = kotlin.target.compilations
    compilations.matching { it.name == "testFixtures" }.configureEach {
        associateWith(compilations.getByName("main"))
        compilations.getByName("test").associateWith(this)
    }
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
