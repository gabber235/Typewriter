import org.gradle.kotlin.dsl.protokt

plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.protokt)
    alias(libs.plugins.kotlin.serialize)
}

dependencies {
    implementation("com.typewritermc:service-utils")
    implementation(libs.protobuf.java)
    implementation(libs.nats.core)
    implementation(libs.nats.jetstream)
    implementation(libs.kotlin.serialize.json)
}

protokt {
    generate {
        grpcDescriptors = false
        grpcKotlinStubs = false
    }
}

sourceSets {
    main {
        proto {
            srcDir("../../../proto")
        }
    }
}