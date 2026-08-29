plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    api(project(":service-registrar-core"))
    implementation("com.typewritermc:service-utils")
    implementation(libs.kotlin.coroutines.core)
    implementation(libs.kotlin.serialize.json)
    testImplementation(libs.kotlin.coroutines.test)
}
