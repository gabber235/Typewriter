// Code that compiles against Paper: the Paper engine and every extension's Paper part. Paper publishes its API for
// Java 25 only, so each compile classpath asks for libraries that run on Java 25; every other library runs on 21 and
// so on 25 as well. The Paper API itself comes from engine-paper, which passes it on to parts built against it.
repositories {
    maven("https://repo.papermc.io/repository/maven-public/")
}

// After evaluation, so it overrides the Java 21 request the JVM plugin attaches to each source set's classpath, and
// reaches source sets an Imprint extension declares later in its build script.
afterEvaluate {
    configurations.matching { it.name.endsWith("CompileClasspath") || it.name == "compileClasspath" }.configureEach {
        attributes.attribute(TargetJvmVersion.TARGET_JVM_VERSION_ATTRIBUTE, 25)
    }
}
