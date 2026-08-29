plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api("com.typewritermc:discovery-model")
    api("com.typewritermc:element-types")
    api("com.typewritermc:presentation-types")
    api("com.typewritermc:realm-capability-types")
    api("com.typewritermc:typewriter-types-core")
    api(libs.kotlin.coroutines.core)
}
