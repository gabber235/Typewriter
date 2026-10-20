plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(project(":typewriter-contracts"))
    implementation("com.typewritermc:imprint-model")
    implementation(libs.ksp.api)
    implementation(libs.kotlinpoet)
    implementation(libs.kotlinpoet.ksp)
    implementation(libs.kotlin.serialize.cbor)
    testImplementation(libs.mockk)
    testImplementation(libs.kctfork.core)
    testImplementation(libs.kctfork.ksp)
    testImplementation(project(":typewriter-api"))
}

tasks.test {
    // Fixtures resolve relative to the module directory.
    workingDir = projectDir
    inputs.dir("src/test/fixtures")
}
