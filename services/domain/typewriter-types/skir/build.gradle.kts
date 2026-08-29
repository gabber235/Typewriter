plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":typewriter-types-core"))
    api("com.typewritermc:service-communicator-skir")
}
