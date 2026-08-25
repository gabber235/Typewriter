plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(project(":page-types"))
    implementation("com.typewritermc:library-types")
    implementation("com.typewritermc:codegen-utils")
    implementation("com.typewritermc:discovery-model")
    implementation("com.typewritermc:discovery-runtime")
    implementation("com.typewritermc:imprint-model")
    implementation(libs.ksp.api)
    implementation(libs.kotlinpoet)
    implementation(libs.kotlinpoet.ksp)
    implementation(libs.kotlin.serialize.cbor)
}
