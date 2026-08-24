plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api("com.typewritermc:service-communicator-skir")
    api("com.typewritermc:typewriter-types-skir")
    api(libs.kotlin.coroutines.core)
    testImplementation(libs.bundles.basic.test)
}
