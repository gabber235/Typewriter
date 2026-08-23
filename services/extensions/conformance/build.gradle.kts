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
                capability("com.typewritermc:engine-conformance-base", version = "^1")
            }
        }
        sourceSet("capabilityConformanceComposite") {
            capabilities {
                capability("com.typewritermc:engine-conformance-composite", version = "^1")
            }
            includes("capabilityConformanceBase")
        }
        sourceSet("capabilityMinecraft") {
            capabilities {
                capability("com.typewritermc:engine-minecraft", version = "^1")
            }
        }
        sourceSet("engineConformance") {
            engine("com.typewritermc:engine-conformance", version = "^1")
            includes("capabilityConformanceComposite")
        }
        sourceSet("enginePaper") {
            engine("com.typewritermc:engine-paper", version = "^1")
            includes("capabilityMinecraft")
        }
        sourceSet("panel") {
            engine("com.typewritermc:engine-panel", version = "^1")
        }
    }
}

dependencies {
    imprintExtensionApi(project(":extension-types"))
    imprintProcessors("com.typewritermc:typewriter-types-codegen")
    imprintProcessors("com.typewritermc:element-codegen")
    imprintProcessors("com.typewritermc:discovery-codegen")
    testImplementation(project(":extension-types"))
}
