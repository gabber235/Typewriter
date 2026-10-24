package main

import "dagger/typewriter/internal/dagger"

func (m *Typewriter) servicesGradleContainer(source *dagger.Workspace) *dagger.Container {
	services := source.Directory("/services", dagger.WorkspaceDirectoryOpts{Gitignore: true})

	return dag.Container().
		From("eclipse-temurin:21-jdk-noble").
		WithDirectory("/workspace/services", services).
		WithDirectory("/workspace/skir-src", source.Directory("/skir-src", defaultWorkspaceOpts)).
		WithMountedCache("/root/.gradle/caches", dag.CacheVolume("services-gradle-caches")).
		WithMountedCache("/root/.gradle/wrapper", dag.CacheVolume("services-gradle-wrapper"))
}

// servicesPayloadFramingNats is the broker of the services payload framing tests. Its users hold the grants the
// backend hands out, so the tests meet the max_payload and response permissions a deployment enforces.
func servicesPayloadFramingNats(source *dagger.Workspace) *dagger.Service {
	return dag.Container().
		From("nats:2.15.0-alpine").
		WithFile("/etc/nats/nats.conf", source.Directory("/services", defaultWorkspaceOpts).
			File("protocol/transport-adapters/kotlin/src/test/fixtures/payload-framing-nats.conf")).
		WithExposedPort(4222).
		AsService(dagger.ContainerAsServiceOpts{
			Args:          []string{"-c", "/etc/nats/nats.conf"},
			UseEntrypoint: true,
		})
}

// ServicesCheck runs every services check against the payload framing broker. CI is set so the broker tests fail
// rather than skip should NATS_URL ever be missing.
//
// +check
func (m *Typewriter) ServicesCheck(source *dagger.Workspace) *dagger.Container {
	return m.servicesGradleContainer(source).
		WithServiceBinding("nats", servicesPayloadFramingNats(source)).
		WithEnvVariable("NATS_URL", "nats://nats:4222").
		WithEnvVariable("CI", "true").
		WithWorkdir("/workspace/services").
		WithExec([]string{"./gradlew", "check", "ktlintCheck", "--no-daemon", "--max-workers=2"}).
		WithExec([]string{"./gradlew", "-p", "imprint", "check", "ktlintCheck", "--no-daemon", "--max-workers=2"})
}
