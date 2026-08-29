plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation(project(":service-file-transfer-core"))
    implementation(libs.kotlin.serialize.cbor)
}
