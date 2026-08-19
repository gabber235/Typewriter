plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":engine-types"))
    api("com.typewritermc:loader-core")
    api("com.typewritermc:extension-types")
    api(libs.kotlin.coroutines.core)
    testImplementation(libs.kotlin.coroutines.test)
}
