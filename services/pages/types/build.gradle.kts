plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api("com.typewritermc:discovery-model")
    api("com.typewritermc:element-types")
    api("com.typewritermc:library-types")
    api("com.typewritermc:typewriter-types-core")
    testImplementation(libs.bundles.basic.test)
}
