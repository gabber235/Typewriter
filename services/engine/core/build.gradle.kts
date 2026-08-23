plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":engine-types"))
    api("com.typewritermc:loader-core")
    api("com.typewritermc:discovery-runtime")
    api("com.typewritermc:element-types")
    api(libs.kotlin.coroutines.core)
    testImplementation(libs.kotlin.coroutines.test)
}
