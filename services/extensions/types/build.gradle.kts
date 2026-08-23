plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api("com.typewritermc:discovery-runtime")
    api("com.typewritermc:element-types")
    api("com.typewritermc:typewriter-types-core")
    api(libs.kotlin.coroutines.core)
}
