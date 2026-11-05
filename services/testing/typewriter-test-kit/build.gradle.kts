plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    api(project(":typewriter-api"))
    implementation(libs.kotlin.coroutines.core)
}
