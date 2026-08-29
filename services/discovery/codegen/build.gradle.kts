plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(project(":discovery-model"))
    implementation(project(":discovery-runtime"))
    implementation("com.typewritermc:codegen-utils")
    implementation("com.typewritermc:typewriter-types-core")
    implementation("com.typewritermc:typewriter-types-ksp")
    implementation(libs.ksp.api)
    implementation(libs.kotlinpoet)
    implementation(libs.kotlinpoet.ksp)
    implementation(libs.kotlin.serialize.cbor)
}
