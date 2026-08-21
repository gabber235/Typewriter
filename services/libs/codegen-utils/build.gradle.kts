plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(libs.ksp.api)
    api(libs.kotlinpoet)
    api(libs.kotlinpoet.ksp)
}
