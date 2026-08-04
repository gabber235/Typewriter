package main

import "dagger/typewriter/internal/dagger"

var serviceGradleRoots = []string{
	"libs/service-utils",
	"libs/service-telemetry",
	"libs/service-http",
	"libs/service-communicator",
	"libs/service-registrar",
	"realm",
}

func (m *Typewriter) servicesGradleContainer(source *dagger.Workspace) *dagger.Container {
	services := source.Directory("/services", dagger.WorkspaceDirectoryOpts{Gitignore: true})

	return dag.Container().
		From("eclipse-temurin:21-jdk-noble").
		WithDirectory("/workspace/services", services).
		WithMountedCache("/root/.gradle/caches", dag.CacheVolume("services-gradle-caches")).
		WithMountedCache("/root/.gradle/wrapper", dag.CacheVolume("services-gradle-wrapper"))
}

// +check
func (m *Typewriter) ServicesCheck(source *dagger.Workspace) *dagger.Container {
	container := m.servicesGradleContainer(source)
	for _, root := range serviceGradleRoots {
		container = container.
			WithWorkdir("/workspace/services/" + root).
			WithExec([]string{"./gradlew", "check", "--no-daemon"})
	}
	return container
}
