plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.ksp)
    `java-library`
    `java-test-fixtures`
}

// The formula language shared by the Realm and the engine: parser, checker, interpreter and the tracked query graph.
dependencies {
    api(project(":typewriter-api"))
    implementation(project(":internal-utils"))
    testImplementation(libs.kotest.property)
    // The tests' code records and providers get real bindings and invocations.
    kspTest(project(":typewriter-codegen"))
}

ksp {
    arg("typewriter.artifactId", "typewritermc:formula-test")
    arg("typewriter.sourcePart", "test")
}
