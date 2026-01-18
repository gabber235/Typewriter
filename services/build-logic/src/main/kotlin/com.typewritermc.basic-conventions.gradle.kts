import java.util.concurrent.TimeUnit

plugins {
    id("org.jetbrains.kotlin.jvm")
}

group = "com.typewritermc"

repositories {
    mavenCentral()
    maven {
        name = "GitHubPackages"
        url = uri("https://maven.pkg.github.com/gabber235/nats.kt")
        credentials {
            username = System.getenv("GITHUB_ACTOR")
                ?: "gh api user --jq .login".runCommand()
                        ?: ""
            password = System.getenv("GITHUB_TOKEN")
                ?: "gh auth token".runCommand()
                        ?: ""
        }
    }
}

kotlin {
    jvmToolchain(21)
}

val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")
dependencies {
    implementation(platform(libs.findLibrary("koin-bom").get()))
    implementation(libs.findBundle("basic-implementation").get())

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
} catch (e: Exception) {
    null
}
