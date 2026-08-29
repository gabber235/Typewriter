plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    api(libs.kotlin.coroutines.core)
    testImplementation(libs.kotlin.coroutines.test)
}
