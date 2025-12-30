plugins {
    id("com.typewritermc.basic-conventions")
    application
    alias(libs.plugins.kotlin.serialize)
    alias(libs.plugins.gradle.buildconfig)
}

version = "1000.0.0"

application {
    mainClass.set("com.typewritermc.realm.RealmMain")
}

dependencies {
    implementation(libs.logback)
    implementation(libs.kotlin.serialize.cbor)
    implementation("com.typewritermc:service-registrar")
    implementation("com.typewritermc:service-communicator")
}

buildConfig {
    packageName("com.typewritermc.realm")
    useKotlinOutput {
        topLevelConstants = true
        internalVisibility = false
    }
    buildConfigField<String>("REALM_VERSION", provider { "${project.version}" })
}