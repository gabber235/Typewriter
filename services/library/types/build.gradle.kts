plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api("com.typewritermc:element-types")
    api("com.typewritermc:typewriter-types-core")
    implementation(libs.kotlin.serialize.json)
    testImplementation(libs.bundles.basic.test)
}
