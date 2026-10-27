plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
    `java-test-fixtures`
}

dependencies {
    api(project(":protocol"))
    api("com.typewritermc:imprint-model")
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    api(libs.kotlin.serialize.core)
    implementation(libs.kotlin.serialize.cbor)
    implementation(libs.kotlin.serialize.json)
    testImplementation(project(":typewriter-test-kit")) { exclude(module = "typewriter-api") }
}
