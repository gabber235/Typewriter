plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    implementation(project(":loader-core"))
    testImplementation(libs.kotlin.coroutines.test)
}
