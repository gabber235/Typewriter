plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(libs.kotlin.serialize.core)
    implementation(libs.kotlin.serialize.json)
    implementation("com.typewritermc:service-communicator")
}