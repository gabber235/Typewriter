plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(project(":typewriter-types-core"))
    implementation(project(":typewriter-types-ksp"))
    implementation("com.typewritermc:codegen-utils")
    implementation("com.typewritermc:discovery-model")
    implementation(libs.ksp.api)
    implementation(libs.kotlinpoet)
    implementation(libs.kotlinpoet.ksp)
    implementation(libs.kotlin.serialize.cbor)
}
