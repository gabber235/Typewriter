plugins {
    id("com.typewritermc.basic-conventions")
    `java-gradle-plugin`
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(project(":imprint-model"))
    implementation(libs.kotlin.gradle.plugin)
    implementation(libs.ksp.gradle.plugin)
    implementation(libs.kotlin.serialize.cbor)
    implementation(libs.semver)
    implementation("com.gradleup.shadow:shadow-gradle-plugin:9.4.1")
    testImplementation(gradleTestKit())
}

gradlePlugin {
    plugins {
        create("imprint") {
            id = "com.typewritermc.imprint"
            implementationClass = "com.typewritermc.imprint.gradle.ImprintPlugin"
            displayName = "Typewriter Imprint"
            description = "Configures Typewriter engine, engine capability, and extension projects"
        }
    }
}
