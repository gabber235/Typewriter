plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-test-fixtures`
}

dependencies {
    implementation(project(":typewriter-contracts"))
    implementation("com.typewritermc:imprint-model")
    implementation(libs.ksp.api)
    implementation(libs.kotlinpoet)
    implementation(libs.kotlinpoet.ksp)
    implementation(libs.kotlin.serialize.cbor)
    testFixturesApi(libs.kctfork.core)
    testFixturesApi(libs.kctfork.ksp)
    testFixturesApi(project(":typewriter-api"))
}

tasks.test {
    // Fixtures resolve relative to the module directory.
    workingDir = projectDir
    inputs.dir("src/test/fixtures")
}
