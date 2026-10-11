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
    testImplementation(libs.bundles.basic.test)
}
