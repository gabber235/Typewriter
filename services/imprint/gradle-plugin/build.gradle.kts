plugins {
    id("com.typewritermc.basic-conventions")
    `java-gradle-plugin`
}

dependencies {
    implementation(project(":imprint-model"))
    implementation(libs.kotlin.gradle.plugin)
    implementation(libs.ksp.gradle.plugin)
    testImplementation(gradleTestKit())
}

gradlePlugin {
    plugins {
        create("imprint") {
            id = "com.typewritermc.imprint"
            implementationClass = "com.typewritermc.imprint.gradle.ImprintPlugin"
            displayName = "Typewriter Imprint"
            description = "Configures Typewriter engine, engine layer, and extension projects"
        }
    }
}
