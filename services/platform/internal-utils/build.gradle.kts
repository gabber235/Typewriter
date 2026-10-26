plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
}

dependencies {
    api(libs.kotlin.coroutines.core)
    testImplementation(libs.kotlin.coroutines.test)
}
