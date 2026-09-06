plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    alias(libs.plugins.kotlin.serialize)
}

typewriter {
    extension {
        id = "typewritermc:conformance"
        version = "1.0.0"

        sourceSet("capabilityConformanceBase") {
            capabilities {
                capability(project(":engine-conformance-base"), version = "^1")
            }
        }
        sourceSet("capabilityConformanceComposite") {
            capabilities {
                capability(project(":engine-conformance-composite"), version = "^1")
            }
            includes("capabilityConformanceBase")
        }
        sourceSet("capabilityMinecraft") {
            capabilities {
                capability(project(":engine-minecraft"), version = "^1")
            }
        }
        sourceSet("engineConformance") {
            engine(project(":engine-conformance"), version = "^1")
            includes("capabilityConformanceComposite")
        }
        sourceSet("enginePaper") {
            engine(project(":engine-paper"), version = "^1")
            includes("capabilityMinecraft")
        }
        sourceSet("panel") {
            engine(project(":engine-panel"), version = "^1")
        }
    }
}

dependencies {
    add("commonImplementation", project(":typewriter-api"))
    imprintExtensionApi(project(":typewriter-api"))
    imprintExtensionApi(libs.kotlin.coroutines.core)
    testImplementation(project(":typewriter-api"))
    testImplementation(libs.kotlin.coroutines.core)
}
