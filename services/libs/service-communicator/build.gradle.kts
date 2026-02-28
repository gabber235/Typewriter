import org.gradle.kotlin.dsl.protokt

plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.protokt)
    alias(libs.plugins.kotlin.serialize)
    `java-test-fixtures`
}

dependencies {
    implementation("com.typewritermc:service-utils")
    implementation(libs.protobuf.java)
    implementation(libs.nats.core)
    implementation(libs.nats.jetstream)
    implementation(libs.kotlin.serialize.json)
    
    testFixturesImplementation("com.typewritermc:service-utils")
    testFixturesImplementation(libs.nats.core)
    testFixturesImplementation(libs.kotlin.coroutines.core)
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