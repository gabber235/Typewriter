plugins {
    id("com.typewritermc.basic-conventions")
}

version = "1000.0.0"

dependencies {
    implementation(project(":loader-core"))
    implementation(libs.clikt)
    implementation(libs.jline)
    testImplementation(libs.kotlin.coroutines.test)
    testImplementation(project(":telemetry"))
    testImplementation(libs.mockk)
}

fun registerRunProfile(profile: String) {
    val profileName = profile.replaceFirstChar(Char::uppercase)
    val configurationFile = rootProject.layout.projectDirectory.file("runtime/config/$profile.properties")
    tasks.register<JavaExec>("run$profileName") {
        group = "application"
        description = "Runs the standalone loader with the $profile configuration."
        dependsOn(tasks.named("classes"))
        classpath = sourceSets.main.get().runtimeClasspath
        mainClass.set("com.typewritermc.loader.standalone.StandaloneLoader")
        standardInput = System.`in`
        environment("TYPEWRITER_CONFIG_FILE", configurationFile.asFile.absolutePath)
        inputs.file(configurationFile)
    }
}

registerRunProfile("local")
registerRunProfile("production")
