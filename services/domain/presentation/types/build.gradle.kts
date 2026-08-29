plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api("com.typewritermc:realm-capability-types")
    api("com.typewritermc:service-communicator-skir")
    api("com.typewritermc:typewriter-types-skir")
    testImplementation(libs.bundles.basic.test)
}
